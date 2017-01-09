#!groovy

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

      sh "bundle install"

      stage('Test') {
        // FIXME: enable tests
        // sh "bundle exec fastlane test"
      }

      stage('Build') {
        sh "bundle exec fastlane build"
      }

      stage('Archive') {
        def currentVersion = 'v' + getVersion()
        def archiveName = "realm_browser_${currentVersion}.zip"

        dir("build") {
          sh "zip --symlinks -r ${archiveName} *"
          archive "${archiveName}"
        }
      }
    }
  }
}

def getVersion() {
  sh '''
    awk  '/<key>CFBundleShortVersionString<\\/key>/ { getline; gsub("<[^>]*>", ""); gsub(/\\t/,""); print $0 }' RealmBrowser/Supporting\\ Files/RealmBrowser-Info.plist > currentversion
  '''
  def versionNumber = readFile('currentversion').readLines()[0]

  sh "git rev-parse HEAD | cut -b1-8 > sha.txt"
  def sha = readFile('sha.txt').readLines().last().trim()

  return "${versionNumber}-${sha}"
}
