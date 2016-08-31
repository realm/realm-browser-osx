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


def gitTag
def gitSha


def get_version(String version){
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
    checkout scm
    sh 'git clean -ffdx -e .????????'
  }

  sh '''
    awk  '/<key>CFBundleShortVersionString<\\/key>/ { getline; gsub("<[^>]*>", ""); gsub(/\\t/,""); print $0 }'  realm-browser/RealmBrowser/Supporting\\ Files/RealmBrowser-Info.plist > currentversion
  '''
  def currentVersionNumber = readFile('currentversion').readLines()[0]

  def currentVersion = 'v' + get_version(currentVersionNumber)
  def archiveName = "realm_browser_${currentVersion}.zip"
  echo archiveName

  dir('realm-browser') {
    sh 'pod update'
    sh 'pod install'

    //FIXME build debug version and test
    stage 'Build debug'
    //sh "xcodebuild -workspace RealmBrowser.xcworkspace -scheme 'Realm Browser' -configuration Debug -derivedDataPath 'build/DerivedData' CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO clean build"

    stage 'Test'
    //sh "xcodebuild -workspace RealmBrowser.xcworkspace -scheme 'Realm Browser' -configuration Debug -derivedDataPath 'build/DerivedData' CODE_SIGN_IDENTITY= CODE_SIGNING_REQUIRED=NO test"

    stage 'Build'
    sh "xcodebuild -workspace RealmBrowser.xcworkspace -scheme 'Realm Browser' -configuration Release -derivedDataPath 'build/DerivedData' CODE_SIGN_IDENTITY='Developer ID Application' clean build"

  }

    stage 'Package'
    dir("build/DerivedData/Build/Products/Release/") {
        sh "ls -alh"
        sh "zip --symlinks -r ${archiveName} 'Realm Browser.app'"

        archive "${archiveName}"

        if (['sync'].contains(env.BRANCH_NAME) || gitTag != "") {
            stage 'trigger release'
            sh "/usr/local/bin/s3cmd put ${archiveName} 's3://realm-ci-artifacts/browser/${currentVersionNumber}/cocoa/'"
            echo "Uploaded to 's3://realm-ci-artifacts/browser/${currentVersionNumber}/cocoa/'"
        }
    }
}
