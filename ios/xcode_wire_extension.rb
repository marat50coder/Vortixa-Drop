# Xcode wiring for Vortixa Drop (GoogleService, privacy manifest,
# entitlements, Notification Service Extension).
#
# Idempotent. From `ios`:
#     ruby xcode_wire_extension.rb

require 'xcodeproj'

PROJECT_PATH = File.expand_path('Runner.xcodeproj', __dir__)
EXTENSION_NAME = 'NotificationService'
EXTENSION_BUNDLE_ID = 'com.vortixadrop.vortixadropgame.NotificationService'
DEPLOYMENT_TARGET = '15.0'
TEAM_ID = 'VC9SMD7JW3'.freeze

project = Xcodeproj::Project.open(PROJECT_PATH)
runner = project.targets.find { |t| t.name == 'Runner' } || abort('Runner target not found')

# -----------------------------------------------------------------------------
# 1. Runner resources: GoogleService-Info.plist and PrivacyInfo.xcprivacy.
# -----------------------------------------------------------------------------
def ensure_resource(project, group, target, filename)
  ref = group.files.find { |f| f.path == filename }
  ref ||= group.new_reference(filename)
  target.resources_build_phase.add_file_reference(ref, true) unless \
    target.resources_build_phase.files_references.include?(ref)
  ref
end

runner_group = project.main_group['Runner'] || abort('Runner group missing')

ensure_resource(project, runner_group, runner, 'GoogleService-Info.plist')
ensure_resource(project, runner_group, runner, 'PrivacyInfo.xcprivacy')

# -----------------------------------------------------------------------------
# 2. Entitlements per configuration.
# -----------------------------------------------------------------------------
runner.build_configurations.each do |config|
  entitlement = if config.name.downcase.start_with?('release')
                  'Runner/RunnerRelease.entitlements'
                else
                  'Runner/Runner.entitlements'
                end
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = entitlement
end

# -----------------------------------------------------------------------------
# 3. Notification Service Extension target.
# -----------------------------------------------------------------------------
existing = project.targets.find { |t| t.name == EXTENSION_NAME }
extension_target = existing || project.new_target(
  :app_extension,
  EXTENSION_NAME,
  :ios,
  DEPLOYMENT_TARGET
)

# Group + file references.
extension_group = project.main_group[EXTENSION_NAME] || project.main_group.new_group(
  EXTENSION_NAME,
  EXTENSION_NAME
)

swift_ref = extension_group.files.find { |f| f.path == 'NotificationService.swift' }
swift_ref ||= extension_group.new_reference('NotificationService.swift')
plist_ref = extension_group.files.find { |f| f.path == 'Info.plist' }
plist_ref ||= extension_group.new_reference('Info.plist')

# Compile sources.
already_compiled = extension_target.source_build_phase.files_references.include?(swift_ref)
extension_target.source_build_phase.add_file_reference(swift_ref, true) unless already_compiled

# Info.plist should NOT be compiled; make sure it is not attached to any
# compile phase — file reference is enough because build settings point at it.
extension_target.source_build_phase.files.each do |f|
  f.remove_from_project if f.file_ref == plist_ref
end

# Build settings for every config.
extension_target.build_configurations.each do |config|
  bs = config.build_settings
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = EXTENSION_BUNDLE_ID
  bs['INFOPLIST_FILE'] = "#{EXTENSION_NAME}/Info.plist"
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SKIP_INSTALL'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['CODE_SIGN_IDENTITY'] = 'Apple Development' if config.name != 'Release'
  bs['CODE_SIGN_IDENTITY'] = 'Apple Distribution' if config.name == 'Release'
  bs['DEVELOPMENT_TEAM'] = TEAM_ID unless TEAM_ID.empty?
  bs['SWIFT_VERSION'] = '5.0'
  bs['ENABLE_BITCODE'] = 'NO'
  bs['MARKETING_VERSION'] = '1.2.0'
  bs['CURRENT_PROJECT_VERSION'] = '3'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
  bs['CLANG_ENABLE_MODULES'] = 'YES'
end

# Attributes: automatic signing at the project level too, so Xcode picks up
# the same style shown in the Signing & Capabilities tab.
project.root_object.attributes['TargetAttributes'] ||= {}
project.root_object.attributes['TargetAttributes'][extension_target.uuid] = {
  'ProvisioningStyle' => 'Automatic'
}

# Make Runner depend on the extension and embed it in the app bundle.
unless runner.dependencies.any? { |d| d.target == extension_target }
  runner.add_dependency(extension_target)
end

embed_phase = runner.copy_files_build_phases.find do |p|
  p.name == 'Embed App Extensions' || p.symbol_dst_subfolder_spec == :plug_ins
end
if embed_phase.nil?
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
end

product_ref = extension_target.product_reference
unless embed_phase.files.any? { |f| f.file_ref == product_ref }
  build_file = embed_phase.add_file_reference(product_ref, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Embed the extension before Thin Binary. Putting it after that script
# creates a copy-files cycle (appex into Runner.app vs Thin Binary
# rewriting Runner.app/Info.plist).
thin_index = runner.build_phases.index { |p| p.display_name == 'Thin Binary' }
runner.build_phases.delete(embed_phase)
if thin_index
  runner.build_phases.insert(thin_index, embed_phase)
else
  runner.build_phases << embed_phase
end

# Runner main target: also flip on automatic signing so the entitlements
# take effect without the developer having to open the Signing tab.
project.root_object.attributes['TargetAttributes'][runner.uuid] ||= {}
project.root_object.attributes['TargetAttributes'][runner.uuid]['ProvisioningStyle'] = 'Automatic'
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_STYLE'] ||= 'Automatic'
end

project.save
puts "Wired #{EXTENSION_NAME} extension, resources and entitlements into Runner.xcodeproj"
