/* Javascript helpers for the "show_feature" page.
/*
/******************************************************************************/

jQuery.noConflict();

window.onload = function()
{
  // Toggle feature value annotations.
  jQuery("span.feature-show-value-expand")
    .click(org.mo.sv.show.toggleFeatureValueAnnotation);
};

// Toggle feature value annotations on the "show_feature" page.
org.mo.sv.show.toggleFeatureValueAnnotation = function()
{
  jQuery(this).siblings("div.feature-show-value-toggle")
    .toggle("fast", function(){
      jQuery(this).empty();
      var span = jQuery(this).siblings("span.feature-show-value-expand")[0];
      span.innerHTML = (span.innerHTML == " [+] ")? " [-] " : " [+] ";
      var uri = jQuery(this).parent("li").attr("id");
      org.mo.sv.submitQuery(
        org.mo.sv.show.queryFeatureValueAnnotation(uri), 
        org.mo.sv.show.queryFeatureValueAnnotationCallback);
    }
  );
};

// Callback funciton to append feature value annotations.
org.mo.sv.show.queryFeatureValueAnnotationCallback = function(response)
{
  jQuery.each(response["results"]["bindings"], function(i, val) {
    if (val["picLink"] != undefined) {
      var img = jQuery("<img class=\"feature-show-value-img\" src=\"" 
        + val["picLink"]["value"] + "\" alt=\"picture preview\" title=\"" 
        + val["picLink"]["value"] + "\"></img>");
      jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle").append(img);
    }
    if (val["description"] != undefined) {
      var desc = jQuery("<div class=\"feature-show-value-description\">" 
        + "<u>Description</u>: <i>" + val["description"]["value"] + "</i></div>");
      jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle").append(desc);
    }
    else {
      jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle")
        .append("<div>No description yet.</div>");
    }
    if (val["reference"] != undefined) {
      var ref = jQuery("<div class=\"feature-show-value-description\">" 
        + "<u>Reference</u>: " + val["reference"]["value"] + "</div>");
      jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle").append(ref);
    }
    else {
      jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle")
        .append("<div>No reference yet.</div>");
    }
    jQuery("li[title=\"" + val["label"]["value"] + "\"]")
        .find("div.feature-show-value-toggle")
        .append("<div style=\"clear:both\"></div>");
  });
};