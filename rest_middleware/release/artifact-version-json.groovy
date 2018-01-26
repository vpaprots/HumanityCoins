import groovy.json.*
import hudson.model.*
import hudson.FilePath
println "Reading version..."

def build = Thread.currentThread().executable

//File f = new File("./release/version.json")
if(build.workspace.isRemote())
{
    channel = build.workspace.channel;
    fp = new FilePath(channel, build.workspace.toString() + "/release/version.json")
} else {
    fp = new FilePath(new File(build.workspace.toString() + "/release/version.json"))
}

def slurper = new JsonSlurper()
def jsonText = fp.readToString()
def versionJSON = slurper.parseText( jsonText )
def versionName = "${versionJSON.major}.${versionJSON.minor}.${versionJSON.revision}"

//newsection
String [] safeParams = []
println "Got to here"
def task = build.buildVariableResolver.resolve("taskType")
println "Got to here"
println "updating revision"
println "Old version is $versionName"
switch (task) {
    case "revision":
        // Update version code
        versionJSON.buildNumber += 1
        versionJSON.revision += 1
        break
    case "minor":
        versionJSON.buildNumber += 1
        versionJSON.minor += 1
        versionJSON.revision = 0
        break
    case "major":
        versionJSON.buildNumber += 1
        versionJSON.major += 1
        versionJSON.minor = 0
        versionJSON.revision = 0
        break
    default:
        break
}
def newVersionName = "${versionJSON.major}.${versionJSON.minor}.${versionJSON.revision}"
println "New version $newVersionName"
ParameterValue[] params = [
        new StringParameterValue("ARTIFACT_VERSION", newVersionName),
]
fp.write(new JsonBuilder(versionJSON).toPrettyString(), null)
//end of newsection


build.actions.add(new ParametersAction(params))
