({
    init : function(component, event, helper) {
        helper.getChatter(component, event, helper);	
    },
    upload : function(component, event, helper) { 
        helper.upload(component, event,helper);
    },
    cancel : function(component, event, helper) { 
        helper.cancel(component, event,helper);
    },
    handleUploadFinished: function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        component.set('v.ID',uploadedFiles[0].documentId);
        component.set('v.docname',uploadedFiles[0].name);
        console.log('nameofdoc',component.get("v.docname"));
    },
    doSave: function(component, event, helper){
        helper.doSave(component, event,helper);
    }
})