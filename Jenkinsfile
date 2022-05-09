#!groovy

node {
    
    // -------------------------------------------------------------------------
    // Defining Org Variables - PRODUCTION
    // -------------------------------------------------------------------------
	
    def SF_CONSUMER_KEY_PROD=env.SF_CONSUMER_KEY_PROD
    def SF_USERNAME_PROD=env.SF_USERNAME_PROD
    def SERVER_KEY_CREDENTIALS_ID_PROD=env.SERVER_KEY_CREDENTIALS_ID_PROD
    def PROD_ORG_ALIAS = 'PROD'
	
    // -------------------------------------------------------------------------
    // Defining Org Variables - Development
    // -------------------------------------------------------------------------
	
    def SF_CONSUMER_KEY_DEV=env.SF_CONSUMER_KEY_DEV
    def SF_USERNAME_DEV=env.SF_USERNAME_DEV
    def SERVER_KEY_CREDENTIALS_ID_DEV=env.SERVER_KEY_CREDENTIALS_ID_DEV
    def DEV_ORG_ALIAS = 'DEV'
	
    // -------------------------------------------------------------------------
    // Defining Org Variables - QA
    // -------------------------------------------------------------------------
	
    def SF_CONSUMER_KEY_QA=env.SF_CONSUMER_KEY_QA
    def SF_USERNAME_QA=env.SF_USERNAME_QA
    def SERVER_KEY_CREDENTIALS_ID_QA=env.SERVER_KEY_CREDENTIALS_ID_QA
    def QA_ORG_ALIAS = 'QA'
	
    //def DEPLOYMENT_TYPE=env.DEPLOYMENT_TYPE // Incremental Deployment = DELTA ; Full Deployment = FULL
    //def SF_SOURCE_COMMIT_ID=env.SOURCE_BRANCH
    //def SF_TARGET_COMMIT_ID=env.TARGET_BRANCH
	
    // -------------------------------------------------------------------------
    // Defining Custom Variables - QA
    // -------------------------------------------------------------------------
    
    def SF_INSTANCE_URL = env.SF_INSTANCE_URL ?: "https://login.salesforce.com"
    def DEPLOYMENT_TYPE= 'FULL' // Incremental Deployment = DELTA ; Full Deployment = FULL
    def DEPLOYDIR='force-app'
    def SF_DELTA_FOLDER='DELTA_PKG'
    def TEST_LEVEL= ''
    def SF_SOURCE_COMMIT_ID='a183bea2459ebb766aeaed287b516eacfd749059'
    def SF_TARGET_COMMIT_ID='fb602c8073b9779a1fb592267ab341c44f3645d9'
    def APEX_PMD = 'True'
    
    //Defining SFDX took kit path against toolbelt
    def toolbelt = tool 'toolbelt'


    // -------------------------------------------------------------------------
    // Check out code from source control.
    // -------------------------------------------------------------------------

    stage('checkout source') {
        checkout scm
    }

    // -------------------------------------------------------------------------
    // Run all the enclosed stages with access to the Salesforce
    // JWT key credentials
    // -------------------------------------------------------------------------

 	withEnv(["HOME=${env.WORKSPACE}"]) {	
	echo "workspace directory is ${workspace}"
	    withCredentials([
		    file(credentialsId: SERVER_KEY_CREDENTIALS_ID_PROD, variable: 'server_key_file_prod'),
		    file(credentialsId: SERVER_KEY_CREDENTIALS_ID_DEV, variable: 'server_key_file_dev')
	    ]) {
		    
		// -------------------------------------------------------------------------
		// Authenticate to Salesforce using the server key.
		// Install Powerkit Plugin
		// -------------------------------------------------------------------------

		stage('Install Powerkit Plugin') {
        		rc = command "echo y | ${toolbelt}sfdx plugins:install sfpowerkit"
    		}
		    
		stage('Authorize Prod Org') {
			when {
				branch 'master'
			}
			steps{
      			bat "${toolbelt}sfdx auth:jwt:grant --instanceurl ${SF_INSTANCE_URL} --clientid ${SF_CONSUMER_KEY_PROD} --jwtkeyfile ${server_key_file_prod} --username ${SF_USERNAME_PROD} --setalias ${PROD_ORG_ALIAS}"	
			}
			//if (rc != 0) {
    			//	error('Authorization Failed.')
			//}
		}
		
		// -------------------------------------------------------------------------
		// APEX PMD Execution
		// -------------------------------------------------------------------------
		    
		stage('ApexPMD_Validation') {
			if (APEX_PMD == 'True')
			{
      				if (DEPLOYMENT_TYPE == 'DELTA')
            			{
            				rc = command "${toolbelt}sfdx sfpowerkit:source:pmd -d ${SF_DELTA_FOLDER}/${DEPLOYDIR} -r Ruleset.xml -o PMD_report.html -f html"
            			}
            			else
            			{
					rc = command "${toolbelt}sfdx sfpowerkit:source:pmd -d ${DEPLOYDIR} -r Ruleset.xml -o PMD_report.html -f html"
            			}
			//publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'coverage', reportFiles: 'PMD_report.html', reportName: 'HTML Report', reportTitles: 'Coverage Report'])
		    	if (rc != 0) 
				{
				error 'PMD Validation Failed.'
		    		}
				}
				else
				{
				echo 'Skipping Apex PMD check'
				}
        	}
		 
		// -------------------------------------------------------------------------
		// Creating Delta Package with the changes.
		// -------------------------------------------------------------------------

		stage('Create Delta Package') {
      			if (DEPLOYMENT_TYPE == 'DELTA'){
				echo "Deploying DELTA Components from Repository"
            				rc = command "${toolbelt}sfdx sfpowerkit:project:diff -d ${SF_DELTA_FOLDER} -r ${SF_SOURCE_COMMIT_ID} -t ${SF_TARGET_COMMIT_ID}"
				if (rc != 0) 
				{
    					error('Delta Package Creation Failed.')
				}
          		}
          		else{
              			echo "Deploying All Components from Repository"
          		}
		}

		// -------------------------------------------------------------------------
		// Validating Stage.
		// -------------------------------------------------------------------------

		stage('Package Validation') {
      			if (DEPLOYMENT_TYPE == 'DELTA')
            		{
            			rc = command "${toolbelt}sfdx force:source:deploy -c -p ${SF_DELTA_FOLDER}/${DEPLOYDIR} -u ${SF_USERNAME} -w 500 -l ${TEST_LEVEL}"
				if (rc != 0) {
    				error('Package Validation Failed.')
				}
            		}
            		else
            		{
            			rc = command "${toolbelt}sfdx force:source:deploy -c -p ${DEPLOYDIR} -u ${SF_USERNAME} -w 500 -l ${TEST_LEVEL}"
				if (rc != 0) {
    				error('Authorization Failed.')
				}
            		}
        	}
		    
		// -------------------------------------------------------------------------
		// Deployment Stage.
		// -------------------------------------------------------------------------
    
		    
		stage('Package Deployment') {
      			if (DEPLOYMENT_TYPE == 'DELTA')
            		{
            			rc = command "${toolbelt}sfdx force:source:deploy -p ${SF_DELTA_FOLDER}/${DEPLOYDIR} -u ${SF_USERNAME} -w 500 -l ${TEST_LEVEL}"
				if (rc != 0) {
    				error('Authorization Failed.')
				}
            		}
            		else
            		{
            			rc = command "${toolbelt}sfdx force:source:deploy -p ${DEPLOYDIR} -u ${SF_USERNAME} -w 500 -l ${TEST_LEVEL}"
            			if (rc != 0) {
    				error('Authorization Failed.')
				}
            		}
        	}
		    
		// -------------------------------------------------------------------------
		// Deploy metadata and execute unit tests.
		// -------------------------------------------------------------------------

		//stage('Deploy and Run Tests') {
		//    rc = command "${toolbelt}/sfdx force:mdapi:deploy --wait 10 --deploydir ${DEPLOYDIR} --targetusername UAT --testlevel ${TEST_LEVEL}"
		//    if (rc != 0) {
		//	error 'Salesforce deploy and test run failed.'
		//    }
		//}
	    }
	}
}

def command(script) {
    if (isUnix()) {
        return sh(returnStatus: true, script: script);
    } else {
		return bat(returnStatus: true, script: script);
    }
}
