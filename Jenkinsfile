#!groovy

def readGitTag() {
  sh "git describe --exact-match --tags HEAD | tail -n 1 > tag.txt 2>&1 || true"
  def tag = readFile('tag.txt').trim()
  return tag
}

def readGitSha() {
  sh "git rev-parse HEAD | cut -b1-8 > sha.txt"
  def sha = readFile('sha.txt').readLines().last().trim()
  return sha
}

def getVersion(String version) {
  def gitTag = readGitTag()
  def gitSha = readGitSha()
  
  if (gitTag == "") {
    return "${version}-g${gitSha}"
  } else {
    return version
  }
}

node('osx_vegas') {
  dir('realm-browser') {
    wrap([$class: 'AnsiColorBuildWrapper']) {
      stage('SCM') {
        checkout([
          $class: 'GitSCM',
          branches: scm.branches,
          gitTool: 'native git',
          extensions: scm.extensions + [[$class: 'CleanCheckout']],
          userRemoteConfigs: scm.userRemoteConfigs
        ])
      }

      sh '''
        awk  '/<key>CFBundleShortVersionString<\\/key>/ { getline; gsub("<[^>]*>", ""); gsub(/\\t/,""); print $0 }' RealmBrowser/Supporting\\ Files/RealmBrowser-Info.plist > currentversion
      '''
      def currentVersionNumber = readFile('currentversion').readLines()[0]
      def currentVersion = 'v' + getVersion(currentVersionNumber)
      def archiveName = "realm_browser_${currentVersion}.zip"
      def gitTag = readGitTag()
      echo archiveName

      sh "bundle install"

      stage('Test') {
        sh "bundle exec fastlane test"
      }

      stage('Build') {
        sh "bundle exec fastlane build"
      }

      stage('Package') {
        dir("build") {
          sh "zip --symlinks -r ${archiveName} *"
          archive "${archiveName}"
        }
      }
    
      if (gitTag != "") {
        stage('Upload to S3') {
          sh "/usr/local/bin/s3cmd put ${archiveName} 's3://realm-ci-artifacts/browser/${currentVersionNumber.split('_')[0]}/cocoa/'"
          echo "Uploaded to 's3://realm-ci-artifacts/browser/${currentVersionNumber.split('_')[0]}/cocoa/'"
        }
      }
    }
  }
}
