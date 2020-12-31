/** 
Description: If the account hierarchy has more than 100 records, this program is called to
partial hierarchy to show - all parents of the current record and one level child records.

- All parent records chaining upto CA Owner are shown; Parent's siblings are not shown
- Current records's siblings are shown, 
- Immediate child records of current record are also shown

//*******
Updates:
01/16/2018 - Changes in class to show only one parent and child up to one level
03/03/2018 - Changes in class to show current record, sibling records, parent and immediate child records.
*/

public with sharing class AccountHierarchyUptoSingleLevel {

     //Declare variables
    public String currentId;
    public List<ObjectStructureMap> asm;
    public List<ObjectStructureMap> lstObjectStructure {get; set;}
    public Map<String, ObjectStructureMap> masm;
    public List<Integer> maxLevel;
    Public Account accountSo {get;set;}
    
    /**
    * Constructor
    */
    public AccountHierarchyUptoSingleLevel(ApexPages.StandardController stdController) {
        this.accountSo= (Account)stdController.getRecord();
        currentId = accountSo.Id;
        this.asm = new List<ObjectStructureMap>{};
        this.masm = new Map<String, ObjectStructureMap>{};
        this.maxLevel = new List<Integer>{};
        
        lstObjectStructure = BindObjectStructure();
    }

    /**
    * Return ObjectStructureMap to page
    * @return asm
    */
    public List<ObjectStructureMap> BindObjectStructure(){
        asm.clear();
        if ( currentId == null ) {
            currentId = System.currentPageReference().getParameters().get( 'id' );
        }
        
        System.assertNotEquals( currentId, null, 'sObject ID must be provided' );
        asm = formatObjectStructure( CurrentId );
        
        return asm;
    }

    /**
    * Query Account from top down to build the ObjectStructureMap
    * @param currentId
    * @return asm
    */
    public ObjectStructureMap[] formatObjectStructure( String currentId ){
    
        List<ObjectStructureMap> asm = new List<ObjectStructureMap>{};
        masm.clear();

        //Change below
        List<Account> al            = new List<Account>{};
        List<ID> currentParent      = new List<ID>{};
        Map<ID, String> nodeList    = new Map<ID, String>{};
        List<String> nodeSortList   = new List<String>{};
        List<Boolean> levelFlag     = new List<Boolean>{};
        List<Boolean> closeFlag     = new List<Boolean>{};
        String nodeId               = '0';
        String nodeType             = 'child';
        Integer count               = 0;
        Integer level               = 0;
        Boolean endOfStructure      = false;
        
        //Find highest level obejct in the structure
        //string TopLevelId = GetTopElement( currentId );
        
        string ParentId = '';
        Account aParent = [Select a.Id, a.ParentId From Account a where a.Id =: currentId limit 1 ];
        
        if ( aParent.ParentID != null ) {
            ParentId = aParent.ParentID;
        }
        
        boolean top = false;
        string objId = currentId;
        Integer countparent = 0;
        map<Integer, Id> mapCurrentId = new map<Integer, Id>();
        List<Integer> lstAllParents = new List<Integer>();
        while ( !top ) {
            Account a = [ Select a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id, a.Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c, Revocation_Status__c from Account a where a.Id =: objId Limit 1];
            if ( a.ParentID != null ) {
                objId = a.ParentID;
                currentParent.add(objId);
                mapCurrentId.put(countparent, objId);
                lstAllParents.add(countparent);
                countparent++;
            }
            else {
                top = true;
            }
        }
        //checking if it is ca owner
        if(lstAllParents.size() == 0){
            Account a = [ Select a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id, a.Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c, Revocation_Status__c from Account a where a.Id =: currentId Limit 1];
            nodeId = ( level > 0 ) ? NodeList.get( a.Id )+'.'+String.valueOf( 0 ) : String.valueOf( 0 );
            masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
            nodeList.put( a.Id,nodeId );
                nodeSortList.add( nodeId );
            level++;
        }
        lstAllParents.sort();
        map<Id,Account> mapal = new map<Id,Account>([ SELECT a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id, a.Status__c, 
            Microsoft_Status__c, SHA_256_Fingerprint__c, Revocation_Status__c FROM Account a WHERE a.id IN : currentParent ORDER BY a.Name]);
        //all parent certificates
        currentParent.clear();
        for ( Integer i = lstAllParents.size()-1 ; i >= 0; i-- ){
            if(mapCurrentId.containskey(i) && mapal.containskey(mapCurrentId.get(i))) {
                Account a = mapal.get(mapCurrentId.get(i));
                system.debug('a :::: '+a.Id + ' a.ParentId :::: '+a.ParentId);
                nodeId = ( level > 0 ) ? NodeList.get( a.ParentId )+'.'+String.valueOf( i ) : String.valueOf( i );
                masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
                //currentParent.add( a.id );
                nodeList.put( a.Id,nodeId );
                nodeSortList.add( nodeId );
                system.debug('nodeList :::: '+nodeList);
                level++;
            }
        }
        
        //all sibling records
        if(string.isnotblank(ParentId)){
            //Query and get all child of current certificates     
            al = [ SELECT a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id, a.Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c, Revocation_Status__c FROM Account a WHERE a.ParentID = : ParentId ORDER BY a.Name ];
            
            for ( Integer i = 0 ; i < al.size(); i++ ){
                //Change below
                Account a = al[i];
                nodeId = ( level > 0 ) ? NodeList.get( a.ParentId )+'.'+String.valueOf( i ) : String.valueOf( i );
                masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
                currentParent.add( a.id );
                nodeList.put( a.id,nodeId );
                nodeSortList.add( nodeId );
            }
        }
        
        //Query and get all child of current certificates 
        if(currentId != null){
            al = [ SELECT a.Type, a.Site, a.ParentId, a.OwnerId, a.Name, a.Industry, a.Id, a.Status__c, Microsoft_Status__c, SHA_256_Fingerprint__c, Revocation_Status__c FROM Account a WHERE a.ParentID = : currentId ORDER BY a.Name ];
            
            for ( Integer i = 0 ; i < al.size(); i++ ){
                //Change below
                Account a = al[i];
                nodeId = ( level > 0 ) ? NodeList.get( a.ParentId )+'.'+String.valueOf( i ) : String.valueOf( i );
                masm.put( NodeID, new ObjectStructureMap( nodeID, levelFlag, closeFlag, nodeType, false, false, a ) );
                currentParent.add( a.id );
                nodeList.put( a.id,nodeId );
                nodeSortList.add( nodeId );
            }
        }
        
        //Account structure must now be formatted
        NodeSortList.sort();
        for( Integer i = 0; i < NodeSortList.size(); i++ ){
            List<String> pnl = new List<String> {};
            List<String> cnl = new List<String> {};
            List<String> nnl = new List<String> {};
            
            if ( i > 0 ){
                String pn   = NodeSortList[i-1];
                pnl     = pn.split( '\\.', -1 );
            }

            String cn   = NodeSortList[i];
            cnl     = cn.split( '\\.', -1 );

            if( i < NodeSortList.size()-1 ){
                String nn = NodeSortList[i+1];
                nnl = nn.split( '\\.', -1 );
            }
            system.debug('cnl :::'+cnl);
            ObjectStructureMap tasm = masm.get( cn );
            if ( cnl.size() < nnl.size() ){
                //Parent
                tasm.nodeType = ( isLastNode( cnl ) ) ? 'parent_end' : 'parent';
            }
            else if( cnl.size() > nnl.size() ){
                tasm.nodeType   = 'child_end';
                tasm.closeFlag   = setcloseFlag( cnl, nnl, tasm.nodeType );
            }
            else{
                tasm.nodeType = 'child';
            }
            
            tasm.levelFlag = setlevelFlag( cnl, tasm.nodeType ); 
            
            //Change below
            if ( tasm.account.id == currentId ) {
                tasm.currentNode = true;
            }
            //if(asm.size() < 1000) {
                asm.add( tasm );
            //}
        }
        if(asm.size() > 0) {
            asm[0].nodeType       = 'start';
            asm[asm.size()-1].nodeType   = 'end';
        }
        return asm;
    }
    
    /**
    * Determin parent elements relationship to current element
    * @return flagList
    */
    public List<Boolean> setlevelFlag( List<String> nodeElements, String nodeType ){
      
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode   = '';
        String workNode   = '';
        Integer cn       = 0;
        system.debug('nodeElements ::: '+nodeElements);
        for( Integer i = 0; i < nodeElements.size() - 1; i++ ){
            cn = Integer.valueOf( nodeElements[i] );
            cn++;
            searchNode   = workNode + String.valueOf( cn );
            workNode   = workNode + nodeElements[i] + '.';
            if ( masm.containsKey( searchNode ) ){
                flagList.add( true );
            }
            else {
                flagList.add( false );
            }
        }
        
        return flagList;
    }
    
    /**
    * Determin if the element is a closing element
    * @return flagList
    */
    public List<Boolean> setcloseFlag( List<String> cnl, List<String> nnl, String nodeType ){
      
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode   = '';
        String workNode   = '';
        Integer cn       = 0;
        
        for( Integer i = nnl.size(); i < cnl.size(); i++ ){
          flagList.add( true );
        }
        
        return flagList;
    }
    
    /**
    * Determin if Element is the bottom node  
    * @return Boolean
    */
    public Boolean isLastNode( List<String> nodeElements ){
      
        String searchNode   = '';
        Integer cn       = 0;
        
        for( Integer i = 0; i < nodeElements.size(); i++ ){
            if ( i == nodeElements.size()-1 ){
                cn = Integer.valueOf( nodeElements[i] );
                cn++;
                searchNode = searchNode + String.valueOf( cn );
            }
            else {
                searchNode = searchNode + nodeElements[i] + '.';
            }
        }
        if ( masm.containsKey( searchNode ) ){
            return false;
        }
        else{
            return true;
        }
    }
    
    /**
    * Find the tom most element in Heirarchy  
    * @return objId
    */
    public String GetTopElement( String objId ){
      
        Boolean top = false;
        while ( !top ) {
            //Change below
            Account a = [ Select a.Id, a.ParentId From Account a where a.Id =: objId limit 1 ];
            
            if ( a.ParentID != null ) {
                objId = a.ParentID;
            }
            else {
                top = true;
            }
        }
        return objId;
    }
    
  /**
    * Wrapper class
    */
    public with sharing class ObjectStructureMap{

        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        
        /**
        * @Change this to your sObject
        */
        public Account account;
        
        public String getnodeId() { return nodeId; }
        public Boolean[] getlevelFlag() { return levelFlag; }
        public Boolean[] getcloseFlag() { return closeFlag; }
        public String getnodeType() { return nodeType; }
        public Boolean getcurrentNode() { return currentNode; }


        /**
        * @Change this to your sObject
        */
        public Account getaccount() { return account; }
        
        public void setnodeId( String n ) { this.nodeId = n; }
        public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
        public void setnodeType( String nt ) { this.nodeType = nt; }
        public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        /**
        * @Change this to your sObject
        */
        public void setaccount( Account a ) { this.account = a; }

        /**
        * @Change the parameters to your sObject
        */
        public ObjectStructureMap( String nodeId, Boolean[] levelFlag,Boolean[] closeFlag , String nodeType, Boolean lastNode, Boolean currentNode, Account a ){
            
            this.nodeId         = nodeId;
            this.levelFlag      = levelFlag; 
            this.closeFlag      = closeFlag;
            this.nodeType       = nodeType;
            this.currentNode    = currentNode;

            //Change this to your sObject  
            this.account = a;
        }
    }
}