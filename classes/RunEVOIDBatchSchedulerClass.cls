/*******************************************************************************************************
 Name: RunEVOIDBatchSchedulerClass

 Dependencies: RunBatchToUpdateEVOIDs controller class, RunEVOIDBatchSchedulerClass class, 
 RunBatchToUpdateEVOIDsTest test class
 
 Description: This batch is created to make callout to EVChecker tool and update 
 “ExtendedValidation.cpp OIDs” field by matching SHA-256 Fingerprint on root certificates.
 
 A scheduler class will run this batch job nightly and update the certs only when there is a 
 change. This process can be run from "Batch Processes" tab too.
 
 The tool (https://evchecker-dot-ccadb-231121.appspot.com) parses a Mozilla file 
 (https://hg.mozilla.org/mozilla-central/file/tip/security/certverifier/ExtendedValidation.cpp) and 
 returns the resuts in JSON:
 
 type EVInfo struct {
    DottedOID         string
    OIDName           string
    SHA256Fingerprint string
    Issuer            string
    Serial            string
 }
 
 This will enable CCADB to:
 - Identify which intermediate certs are enabled for EV, based on the Policy OIDs in their PEM
 - Have a data integrity report comparing EV OIDs known in CCADB versus ExtendedValidation.cpp.
 
 Instructions: Add Remote Site Setting: https://evchecker-dot-ccadb-231121.appspot.com
 
    *****To schedule this Apex class use the developer console and run ***
    RunEVOIDBatchSchedulerClass.scheduleMe('Run Batch To Populate EV OIDs - Daily 4AM');
 *******************************************************************************************************
 Revision History:
 
     11/7/2019 - Created new class.

 ******************************************************************************************************/

global class RunEVOIDBatchSchedulerClass implements Schedulable, Database.AllowsCallouts{
   
    public static String sched = '0 0 4 ? * *';  // everyday at 4 AM 
   
    global static String scheduleMe(String jobNameStr) {
        RunEVOIDBatchSchedulerClass SC = new RunEVOIDBatchSchedulerClass(); 
        return System.schedule(jobNameStr, sched, SC);
    }

    global void execute(SchedulableContext sc) {
        RunBatchToUpdateEVOIDs batch = new RunBatchToUpdateEVOIDs();
        Database.executebatch(batch);
    }
    
}