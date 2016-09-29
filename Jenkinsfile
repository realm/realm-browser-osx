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

def getVersion(String version){
  def gitTag = readGitTag()
  def gitSha = readGitSha()
  if (gitTag == "") {
    return "${version}-g${gitSha}"
  }
  else {
    return version
  }
}

node('osx_vegas') {
  stage 'SCM'
  dir('realm-browser') {
    checkout([
      $class: 'GitSCM',
      branches: scm.branches,
      gitTool: 'native git',
      extensions: scm.extensions + [[$class: 'CleanCheckout']],
      userRemoteConfigs: scm.userRemoteConfigs
    ])
  }

  sh '''
    awk  '/<key>CFBundleShortVersionString<\\/key>/ { getline; gsub("<[^>]*>", ""); gsub(/\\t/,""); print $0 }'  realm-browser/RealmBrowser/Supporting\\ Files/RealmBrowser-Info.plist > currentversion
  '''
  def currentVersionNumber = readFile('currentversion').readLines()[0]

  dir('realm-browser') {
    def currentVersion = 'v' + getVersion(currentVersionNumber)
    def archiveName = "realm_browser_${currentVersion}.zip"
    def gitTag = readGitTag()
    echo archiveName

    sh 'pod repo update'
    sh 'pod install'

    stage 'Test'
    // FIXME Enable tests
    //sh "xcodebuild -workspace RealmBrowser.xcworkspace -scheme 'Realm Browser' -configuration Debug -derivedDataPath 'build/DerivedData' DEVELOPMENT_TEAM=QX5CR2FTN2 CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO clean build test"

    stage 'Build'
    sh "xcodebuild -workspace RealmBrowser.xcworkspace -scheme 'Realm Browser' -configuration Release -derivedDataPath 'build/DerivedData' DEVELOPMENT_TEAM=QX5CR2FTN2 CODE_SIGN_IDENTITY='Developer ID Application' clean build"

    stage 'Package'
    dir("build/DerivedData/Build/Products/Release/") {
      sh "ls -alh"
      sh "zip --symlinks -r ${archiveName} 'Realm Browser.app'"

      archive "${archiveName}"

      if (gitTag != "") {
        stage 'trigger release'
        sh "/usr/local/bin/s3cmd put ${archiveName} 's3://realm-ci-artifacts/browser/${currentVersionNumber.split('_')[0]}/cocoa/'"
        echo "Uploaded to 's3://realm-ci-artifacts/browser/${currentVersionNumber.split('_')[0]}/cocoa/'"
      }
    }
  }
}
