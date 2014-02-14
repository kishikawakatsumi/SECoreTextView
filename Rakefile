desc 'Clean'
task :clean, :schemes do |t, args|
  schemes = args[:schemes].gsub(/'/, '').split(' ')
  schemes.each do |scheme|
    sh "xcodebuild clean -workspace SECoreTextView.xcworkspace -scheme #{scheme} | xcpretty -c; exit ${PIPESTATUS[0]}"
  end
end

desc 'Build'
task :build, :schemes do |t, args|
  schemes = args[:schemes].gsub(/'/, '').split(' ')
  schemes.each do |scheme|
    sh "xcodebuild -workspace SECoreTextView.xcworkspace -scheme #{scheme} CODE_SIGN_IDENTITY=\"\" CODE_SIGNING_REQUIRED=NO | xcpretty -c; exit ${PIPESTATUS[0]}"
  end
end
