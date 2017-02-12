function onSignIn(googleUser) {
  let id_token = googleUser.getAuthResponse().id_token;
  login(id_token);
};

function login(id_token)
{
  let req = new XMLHttpRequest();
  req.onreadystatechange = function () {
    if(req.readyState == XMLHttpRequest.DONE && req.status == 200){
      let res = JSON.parse(req.responseText);
      if(res.valid) {
          sessionStorage.setItem("token", id_token);
          window.location = "reader";
      }
    }
  }

  req.open("GET", "login");
  req.setRequestHeader("Authorization", id_token);
  req.send();
}


let token = sessionStorage.getItem("token");
if(token)
{
    window.location = "reader";
}
