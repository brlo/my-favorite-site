function onTelegramAuth(user) {
  //alert('Logged in as ' + user.first_name + ' ' + user.last_name + ' (' + user.id + (user.username ? ', @' + user.username : '') + ')');
  const params = {
    id: user.id, first_name: user.first_name, last_name: user.last_name, username: user.username, photo_url: user.photo_url, auth_date: user.auth_date, hash: user.hash
  };
  axios.post('/ru/login_telegram/', params)
  .then(function (response) {
    const data = response.data;
    if (data.success == 'ok') {
      window.location.href = data.url;
    } else {
      console.log(data);
    };
  }).catch(function (error) {
    console.log('error', error);
  });
}
