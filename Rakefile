desc 'Clean'
task :clean, :schemes do |t, args|
  schemes = args[:schemes].gsub(/'/, '').split(' ')
  schemes.each do |scheme|
    system("xcodebuild clean -workspace SECoreTextView.xcworkspace -scheme #{scheme} | xcpretty -c")
  end
end

desc 'Build'
task :build, :schemes do |t, args|
  schemes = args[:schemes].gsub(/'/, '').split(' ')
  schemes.each do |scheme|
    system("xcodebuild -workspace SECoreTextView.xcworkspace -scheme #{scheme} CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO | xcpretty -c")
  end
end
