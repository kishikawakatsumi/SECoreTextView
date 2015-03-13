require 'xcjobs'

task :default => ['build:twitter_ios', 'build:text_editor', 'build:twitter_mac']

XCJobs::Build.new('build:twitter_ios') do |t|
  t.workspace = 'SECoreTextView'
  t.scheme = 'TwitterClient-iOS'
  t.configuration = 'Release'
  t.build_dir = 'build'
  t.formatter = 'xcpretty -c'
  t.add_build_setting('CODE_SIGN_IDENTITY', '')
  t.add_build_setting('CODE_SIGNING_REQUIRED', 'NO')
end

XCJobs::Build.new('build:text_editor') do |t|
  t.workspace = 'SECoreTextView'
  t.scheme = 'RichTextEditor'
  t.configuration = 'Release'
  t.build_dir = 'build'
  t.formatter = 'xcpretty -c'
  t.add_build_setting('CODE_SIGN_IDENTITY', '')
  t.add_build_setting('CODE_SIGNING_REQUIRED', 'NO')
end

XCJobs::Build.new('build:twitter_mac') do |t|
  t.workspace = 'SECoreTextView'
  t.scheme = 'TwitterClient-Mac'
  t.configuration = 'Release'
  t.build_dir = 'build'
  t.formatter = 'xcpretty -c'
  t.add_build_setting('CODE_SIGN_IDENTITY', '')
  t.add_build_setting('CODE_SIGNING_REQUIRED', 'NO')
end
