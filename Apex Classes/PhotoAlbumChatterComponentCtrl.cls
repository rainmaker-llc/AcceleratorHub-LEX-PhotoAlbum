public class PhotoAlbumChatterComponentCtrl {
    //Method to return the images and it's details from chatter of current page recordID.
    @AuraEnabled
    public static Map<String,List<Wrapper>> getChatterComponent(String recordId){
        try{
            Set<String> ContentVersionIds = new Set<String>();
            set<String> ContentDocumentIds= new set<String>();
            Map<Id,ContentDocumentLink> ContentDocLinksMap = new Map<Id,ContentDocumentLink>();
            Map<String,List<Wrapper>> data = new Map<String,List<Wrapper>>();
            Map<Id,FeedItem> feedItemMap=new Map<Id,FeedItem>([SELECT Id,body FROM FeedItem WHERE parentId =: recordId]);
            Map<Id,List<FeedAttachment>> feedAttachmentMap=new Map<Id,List<FeedAttachment>>();
            Map<Id,List<FeedComment>> feedCommentMap=new Map<Id,List<FeedComment>>();
            Map<Id,List<String>> feedCommentContentIds=new Map<Id,List<String>>();
            for(FeedAttachment fa : [SELECT Id,RecordId, feedEntityId, Title, Type, Value FROM FeedAttachment WHERE feedEntityId IN :feedItemMap.keySet()]){
                if(fa.recordId.getSObjectType().getDescribe().getName().equalsIgnoreCase('ContentDocument'))
                    ContentDocumentIds.add(fa.recordId);
                else
                    ContentVersionIds.add(fa.recordId);
                if(!feedAttachmentMap.containsKey(fa.feedEntityId))
                    feedAttachmentMap.put(fa.feedEntityId,new List<feedAttachment>());
                
                feedAttachmentMap.get(fa.feedEntityId).add(fa);
            }
            for(FeedComment fc : [SELECT Id, FeedItemId, RelatedRecordId, IsRichText, CommentBody FROM FeedComment WHERE FeedItemId IN :feedItemMap.keySet()]){
                if(fc.RelatedRecordId!=NULL)
                    ContentVersionIds.add(fc.RelatedRecordId);
                if(fc.CommentBody.containsIgnoreCase('<img src="sfdc://')){
                    feedCommentContentIds.put(fc.Id,new List<String>(getContentIds(fc.CommentBody)));
                    ContentDocumentIds.addAll(feedCommentContentIds.get(fc.Id));
                }
                if(!feedCommentMap.containsKey(fc.FeedItemId))
                    feedCommentMap.put(fc.FeedItemId,new List<FeedComment>());
                
                feedCommentMap.get(fc.FeedItemId).add(fc);
            }
            
            for(ContentDocumentLink cdl : [SELECT Id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,ContentDocument.Title,ContentDocument.FileExtension 
                                           FROM ContentDocumentLink 
                                           WHERE ContentDocument.FileExtension IN ('jpg','jpeg','png','gif') AND ContentDocument.LatestPublishedVersionId in :ContentVersionIds AND LinkedEntityId =: recordId]){
                                               System.debug('CDL REcord----ContentDocumentId'+cdl.ContentDocumentId+'-----ContentDocument.LatestPublishedVersionId--'+cdl.ContentDocument.LatestPublishedVersionId);
                                               ContentDocLinksMap.put(cdl.ContentDocument.LatestPublishedVersionId, cdl);
                                           }  
            for(ContentDocumentLink cdl : [SELECT Id,ContentDocumentId,ContentDocument.LatestPublishedVersionId,ContentDocument.Title,ContentDocument.FileExtension 
                                           FROM ContentDocumentLink 
                                           WHERE ContentDocument.FileExtension IN ('jpg','jpeg','png','gif') AND ContentDocumentId IN :ContentDocumentIds AND LinkedEntityId =: recordId]){
                                               System.debug('CDL REcord----ContentDocumentId'+cdl.ContentDocumentId+'-----ContentDocument.LatestPublishedVersionId--'+cdl.ContentDocument.LatestPublishedVersionId);
                                               ContentDocLinksMap.put(cdl.ContentDocumentId, cdl);
                                           }  
            if(!ContentDocLinksMap.isEmpty()){
                data.put('No Tag',new List<Wrapper>());
                for(TopicAssignment TA :[Select Id,EntityId,Topic.Name from TopicAssignment where EntityId IN :feedItemMap.keySet()]){
                    List<Wrapper> lstWrapper=new List<Wrapper>();
                    
                    if(feedItemMap.get(TA.EntityId).Body.containsIgnoreCase('#'+TA.Topic.name) && feedAttachmentMap.containsKey(TA.EntityId)){
                        for(feedAttachment fa : feedAttachmentMap.get(TA.EntityId)){
                            if(ContentDocLinksMap.containsKey(fa.RecordId)){
                                lstWrapper.add(new Wrapper(ContentDocLinksMap.get(fa.RecordId ).ContentDocumentId, 
                                                           ContentDocLinksMap.get(fa.RecordId ).ContentDocument.Title));
                            }
                        }
                        feedAttachmentMap.remove(TA.EntityId);
                    }
                    else if(feedCommentMap.containsKey(TA.EntityId)){
                        for(feedComment fc : feedCommentMap.get(TA.EntityId)){
                            if(fc.CommentBody.containsIgnoreCase('#'+TA.Topic.name)){
                                if(fc.RelatedRecordId!=NULL && ContentDocLinksMap.containsKey(fc.RelatedRecordId)){
                                    lstWrapper.add(new Wrapper(ContentDocLinksMap.get(fc.RelatedRecordId).ContentDocumentId, 
                                                               ContentDocLinksMap.get(fc.RelatedRecordId).ContentDocument.Title));
                                }
                                if(feedCommentContentIds.containsKey(fc.Id)){
                                    for(String contentId : feedCommentContentIds.get(fc.Id)){
                                        if(ContentDocLinksMap.containsKey(contentId)){
                                            lstWrapper.add(new Wrapper(ContentDocLinksMap.get(contentId).ContentDocumentId, 
                                                                       ContentDocLinksMap.get(contentId).ContentDocument.Title));
                                        }
                                    }
                                    feedCommentContentIds.remove(fc.Id);
                                }
                            }
                        }
                    }
                    if(!lstWrapper.isEmpty())
                        data.put(TA.Topic.Name,lstWrapper);
                }
                for(String feedCommentId : feedCommentContentIds.keySet()){
                    for(String ContentId :feedCommentContentIds.get(feedCommentId)){
                        if(ContentDocLinksMap.containsKey(contentId)){
                            data.get('No Tag').add(new Wrapper(ContentDocLinksMap.get(contentId).ContentDocumentId, 
                                                               ContentDocLinksMap.get(contentId).ContentDocument.Title));
                        }
                    }
                }
                for(String feedItemId : feedAttachmentMap.keySet()){
                    for(feedAttachment fa :feedAttachmentMap.get(feedItemId)){
                        if(ContentDocLinksMap.containsKey(fa.RecordId)){
                            data.get('No Tag').add(new Wrapper(ContentDocLinksMap.get(fa.RecordId).ContentDocumentId, 
                                                               ContentDocLinksMap.get(fa.RecordId).ContentDocument.Title));
                        }
                    }
                }
            }     
            return data;         
        }
        catch(exception e){
            System.debug('error---'+e.getMessage()+'----LineNo--'+e.getLineNumber() );
            return null ;
        }
    }
    
    //method to post/insert images and it's details on chatter.
    @AuraEnabled
    public static void saveChunk(Id parentId, String text,String docId,String name) 
    {
        try{
            FeedItem fi = new FeedItem(ParentId = parentId);
            if(String.isBlank(text))
                fi.Body = name.substringBefore('.');
            else
                fi.Body = text;
            
            insert fi;
            if(!String.isBlank(docId)){
                ContentDocument cd= [Select LatestPublishedVersionId FROM ContentDocument WHERE Id =: docId];
                FeedAttachment feedAttachment = new FeedAttachment(FeedEntityId = fi.Id,
                                                                   RecordId = cd.LatestPublishedVersionId,
                                                                   Type = 'Content'
                                                                  );
                insert feedAttachment;
            }
        }
        catch(exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
            
        }
        
    }
    
    //method to get ContentDocumentId from the RichTextArea of the related feedComments on a feedItem.
    public static set<String> getContentIds(String Body){
        set<String> ContentIds =new Set<String>();
        String ContentId='';
        if(Body.containsIgnoreCase('<img src="sfdc://')){
            String subStr=Body.subString(Body.indexOf('<img src="sfdc://'),Body.indexOf('</img>')+6);
            contentId=subStr.subString(subStr.indexOf('//')+2,subStr.IndexOf('"',subStr.indexOf('//')+2));
            Body=Body.remove(subStr);
            ContentIds.addAll(getContentIds(Body));
            if(contentId.length()>=15){
                ContentIds.add(contentId);
            }
        }
        return ContentIds;
    }
    
    //wrapper to contain the title and image of chatter post   
    public class Wrapper{
        @AuraEnabled public String details;
        @AuraEnabled public String title;
        public Wrapper(String details, String title){
            this.details = details;
            this.title = title;
        }
    }
}