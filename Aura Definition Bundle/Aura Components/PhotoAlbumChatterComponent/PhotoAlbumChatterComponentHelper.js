({
    getChatter : function(component, event, helper) {
        component.set('v.dataLoaded',false);
        var action = component.get("c.getChatterComponent");
        action.setParams({
            'recordId' : component.get("v.recordId")
        });
        var keylist=[]; 
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                var response1 = response.getReturnValue();
                var value='';
                Object.keys(response1)
                .sort()
                .forEach(function(v, i) {
                    if(!(v == 'No Tag')){
                        keylist.push(v);
                    }else{
                        value = v;
                    }
                });
                if(!value=='')
                    keylist.push(value);
                component.set('v.keylist',keylist);
                component.set('v.map',response1);
                component.set('v.dataLoaded',true);
            } else if (state === "ERROR") {
                var errors = response.getError();
            }
        });	
        $A.enqueueAction(action);
        
    },
    upload : function(component, event, helper) {
        var container = component.find("upload") ;  
        $A.util.addClass(container, "slds-show"); 
        $A.util.removeClass(container, "slds-hide"); 
    },
    cancel : function(component, event, helper) {
        var container = component.find("upload") ;  
        $A.util.addClass(container, "slds-hide"); 
        $A.util.removeClass(container, "slds-show"); 
    },
    doSave : function(component, event, helper) {
        var action = component.get("c.saveChunk");
        action.setParams({
            'text' : component.find("message-input").getElement().value,
            'docId' : component.get("v.ID"),
            'parentId' : component.get("v.recordId"),
            'name' : component.get("v.docname"),
        });
        component.find("message-input").getElement().value='';
        action.setCallback(this,function(response) 
                           {
                               var state = response.getState();
                               if (state === "SUCCESS"){
                                   if(!alert('Image Uploaded Successfully!')){
                                       $A.get('e.force:refreshView').fire();
                                       this.getChatter(component, event, helper);
                                   }
                               }
                               else if (state === "ERROR") 
                               {
                                   var errors = response.getError();
                                   
                               }
                           });	
        $A.enqueueAction(action);
        var container = component.find("upload");  
        $A.util.addClass(container, "slds-hide"); 
        $A.util.removeClass(container, "slds-show");
    },
    
})