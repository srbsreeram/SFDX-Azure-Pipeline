public with sharing class apexMaster {
    
    public apexMaster() {
        //Constructor
    }

    @AuraEnabled(cacheable=true)
    public static String getHelloWorld() {
        return 'Hello world, Azure DevOps is in the house!';
    }
}
// comment1
//comment2
//commenmt3
