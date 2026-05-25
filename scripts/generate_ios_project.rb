#!/usr/bin/env ruby
# frozen_string_literal: true

require "xcodeproj"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
IOS_DIR = File.join(ROOT, "ios")
PROJECT_PATH = File.join(IOS_DIR, "Shikigami.xcodeproj")
APP_DIR = File.join(IOS_DIR, "Shikigami")
ENGINE_DIR = File.join(ROOT, "Sources", "Engines")

FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)

app_target = project.new_target(:application, "Shikigami", :ios, "17.0")
app_target.product_name = "Shikigami"

app_group = project.main_group.new_group("Shikigami", "Shikigami")
engine_group = project.main_group.new_group("Engines", "../Sources/Engines")
config_group = project.main_group.new_group("Config", "Config")

swift_files = Dir.glob(File.join(APP_DIR, "**", "*.swift")).sort
engine_files = Dir.glob(File.join(ENGINE_DIR, "*.swift")).sort
resource_files = Dir.glob(File.join(APP_DIR, "Resources", "*")).sort

swift_files.each do |path|
  ref = app_group.new_file(path.sub("#{APP_DIR}/", ""))
  app_target.add_file_references([ref])
end

engine_files.each do |path|
  ref = engine_group.new_file(File.basename(path))
  app_target.add_file_references([ref])
end

resource_files.each do |path|
  ref = app_group.new_file(path.sub("#{APP_DIR}/", ""))
  app_target.resources_build_phase.add_file_reference(ref)
end

%w[Base.xcconfig Debug.xcconfig Release.xcconfig Shikigami.entitlements Shikigami-Info.plist].each do |name|
  config_group.new_file(name)
end

supabase_package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
supabase_package.repositoryURL = "https://github.com/supabase/supabase-swift.git"
supabase_package.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "2.0.0"
}

revenuecat_package = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
revenuecat_package.repositoryURL = "https://github.com/RevenueCat/purchases-ios.git"
revenuecat_package.requirement = {
  "kind" => "upToNextMajorVersion",
  "minimumVersion" => "5.0.0"
}

project.root_object.package_references << supabase_package
project.root_object.package_references << revenuecat_package

{
  "Supabase" => supabase_package,
  "RevenueCat" => revenuecat_package
}.each do |product_name, package|
  product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  product.product_name = product_name
  product.package = package
  app_target.package_product_dependencies << product
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  app_target.frameworks_build_phase.files << build_file
end

project.build_configurations.each do |config|
  config.base_configuration_reference = config_group.files.find { |file| file.path == "#{config.name}.xcconfig" }
end

app_target.build_configurations.each do |config|
  config.base_configuration_reference = config_group.files.find { |file| file.path == "#{config.name}.xcconfig" }
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "Config/Shikigami.entitlements"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
  config.build_settings["DEVELOPMENT_TEAM"] = "$(DEVELOPMENT_TEAM)"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  config.build_settings["INFOPLIST_FILE"] = "Config/Shikigami-Info.plist"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.0"
  config.build_settings["MARKETING_VERSION"] = "0.1.0"
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "$(PRODUCT_BUNDLE_IDENTIFIER)"
  config.build_settings["SWIFT_VERSION"] = "5.9"
  config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
end

project.save
puts "Generated #{PROJECT_PATH}"
