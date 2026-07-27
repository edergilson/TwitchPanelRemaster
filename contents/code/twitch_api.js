.pragma library

const CLIENT_ID = "jf1hcvdeadw56lc2boxg0lvl7bs6ua"; // Mantenha o seu ID!
var avatarCache = {};

function getFollowedStreams(userId, token, callback) {
    let xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.twitch.tv/helix/streams/followed?user_id=" + userId);
    xhr.setRequestHeader("Client-Id", CLIENT_ID);
    xhr.setRequestHeader("Authorization", "Bearer " + token);

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                callback(null, JSON.parse(xhr.responseText));
            } else {
                callback({status: xhr.status, data: xhr.responseText}, null);
            }
        }
    }
    xhr.send();
}

// NOVA FUNÇÃO: Busca detalhes dos usuários (incluindo foto)
function getUsers(userIds, token, callback) {
    if (!userIds || userIds.length === 0) {
        callback(null, {data: []});
        return;
    }

    // Constrói a query string ?id=1&id=2&id=3...
    let query = userIds.map(id => "id=" + id).join("&");

    let xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.twitch.tv/helix/users?" + query);
    xhr.setRequestHeader("Client-Id", CLIENT_ID);
    xhr.setRequestHeader("Authorization", "Bearer " + token);

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                callback(null, JSON.parse(xhr.responseText));
            } else {
                callback({status: xhr.status}, null);
            }
        }
    }
    xhr.send();
}

function getCachedAvatar(userId) {
    return avatarCache[userId] || "";
}
