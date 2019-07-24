({
	doInit : function(component, event, helper) {
        var key = component.get("v.key");
        component.set("v.key",key);
        console.log('k',key);
        var map = component.get("v.map");
        var val =map[key];
       console.log('value&&&&&&&&',map);

        component.set("v.value" , map[key]);
    },
    display : function(component, event, helper) {
       var imgsrc = event.target.src;
        var header= event.target.alt;
        component.set("v.imgsrc",imgsrc);
        component.set("v.header",header);
        
        var model = component.find("display");
        $A.util.addClass(model,"slds-show");
        $A.util.removeClass(model,"slds-hide");
        //window.location=data;
    },
})