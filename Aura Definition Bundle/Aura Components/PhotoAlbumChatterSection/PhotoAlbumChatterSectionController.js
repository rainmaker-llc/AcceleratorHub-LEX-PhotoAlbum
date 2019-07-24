({
	toggleSection : function(component, event, helper) { 
        var section = component.find("section-main");
        console.log(section);
        $A.util.toggleClass(section, "slds-is-open");
        if(component.get("v.sectionIcon") == "utility:right") {
            component.set("v.sectionIcon", "utility:down");
        } else {
            component.set("v.sectionIcon", "utility:right");
        }
    }
})