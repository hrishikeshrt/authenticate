// ==UserScript==
// @name        IronPort Authenticate
// @namespace   http://hrishirt.cse.iitk.ac.in/gm/
// @description Refresh IronPort Authentication
// @include     https://authenticate.iitk.ac.in/netaccess/*
// @version     4
// @grant       GM_getValue
// @grant       GM_setValue
// @grant       GM_deleteValue
// @grant       GM_xmlhttpRequest
// @grant       GM_registerMenuCommand
// ==/UserScript==

GM_registerMenuCommand("Reset Login Details", resetLoginDetails, "r");

var CurrentURL = document.URL;
PageURL = CurrentURL.split("/netaccess/");
PageURL = PageURL[1].split(".html");

connStatusURL = 'https://authenticate.iitk.ac.in/netaccess/connstatus.html';
// noproxyAuthURL = 'https://authenticate.iitk.ac.in/netaccess/loginuser.html';
httpsAuthURL1 = 'https://ironport1.iitk.ac.in/B0001D0000N0000F0000S0000R0004/https://www.google.co.in/';
httpsAuthURL2 = 'https://ironport2.iitk.ac.in/B0001D0000N0000F0000S0000R0004/https://www.google.co.in/';

refreshDuration = (9 * 60000);  // refresh in ms  = ( refreshMin * 60 * 1000 )

// force load url every refresh duration
// ver 4: made timer global

setTimeout(connStatus,refreshDuration);

// If direct failure detected
if ( document.body.innerHTML.match("The requested URL could not be retrieved") ) {
  connStatus();
}

// details display

var details = document.createElement('div');
details.setAttribute('id','details');
details.setAttribute('style', 'position:fixed; top:10; right:10;');
document.body.insertBefore(details, document.body.firstChild);
var detail_box = document.getElementById('details');

// begin

getLoginDetails();

user = GM_getValue("IITK_User");
pass = GM_getValue("IITK_Pass");

/* ********** authentication ********** */

// Failed Login
if (document.body.innerHTML.match("Credentials Rejected")) {
  resetLoginDetails();
}

// Requires Login
if (document.body.innerHTML.match("Log In Now")) {
  var login_button = document.getElementsByName("login")[0];
  login_button.click();
}

// Provide details
if (document.body.innerHTML.match("Enter the following information to log in to the remote network")) {
  var user_field = document.getElementsByName("username")[0];
  var pass_field = document.getElementsByName("password")[0];

  var login_button = document.getElementsByName("Login")[0];

  user_field.value = user;
  pass_field.value = pass;
  login_button.click();
}

// Logged In
if (document.body.innerHTML.match("You are logged in")) {
  var cur_time=new Date();

  detail_box.innerHTML+='<b>Last Refresh</b>: '+cur_time.toLocaleTimeString()+'<br><b>Next Refresh:</b> In '+(refreshDuration/60000)+' minutes<br>';
//  setTimeout(connStatus,refreshDuration);

  httpsAuth(user,pass,httpsAuthURL1,"ironport1");
  httpsAuth(user,pass,httpsAuthURL2,"ironport2");

}

/* ********** functions ********** */

function httpsAuth (u,p,l,w) {
  GM_xmlhttpRequest({
    method: 'GET',
    url: l,
    user: u,
    password: p,

    onload: function(responseDetails) {
      var stuff = responseDetails.responseText;
      // alert(stuff);
      var details_box = document.getElementById('details');
      details_box.innerHTML += "<br><b>HTTPS Auth</b> (" + w + ") : ";
      if (stuff.match("WWW_AUTH_REQUIRED")) {
        details_box.innerHTML += "<span style='color:red;'><b>Failure!</b></span>";
      } else {
        if (stuff.match("<title>Google</title>")) {
          details_box.innerHTML += "<span style='color:green;'><b>Success!</b></span>";
        }
      }
    },
    onerror: function(responseDetails) {
      var details_box = document.getElementById('details');
      details_box.innerHTML += "<br><br><b>HTTPS Auth</b> (" + w + ") : ";
      details_box.innerHTML += "<span style='color:red;'><b>Failure!</b></span>";
  
      details_box.innerHTML += "<br>Error Code: " + responseDetails.status + "<br>" + responseDetails.statusText;
    }
  });
}

function connStatus() {
  location.href = connStatusURL;
}

function resetLoginDetails () {
  GM_deleteValue("IITK_User");
  GM_deleteValue("IITK_Pass");
  alert("Login details cleared!")
}

function getLoginDetails() {
  if (!GM_getValue("IITK_User")) {
    ans_user = prompt("Enter IITK Username: ","");
    if (ans_user) { GM_setValue("IITK_User",ans_user) }
    else getLoginDetails();
  }
  if (!GM_getValue("IITK_Pass")) {
    ans_pass = prompt("Enter IITK Password for '"+GM_getValue("IITK_User")+"' : ","");
    if (ans_pass) { GM_setValue("IITK_Pass",ans_pass) }
    else getLoginDetails();
  }
}
