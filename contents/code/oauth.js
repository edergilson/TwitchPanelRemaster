.pragma library

const CLIENT_ID = "jf1hcvdeadw56lc2boxg0lvl7bs6ua"; // Registre na Twitch Developer Console

function startDeviceFlow(callback) {
    let xhr = new XMLHttpRequest();
    xhr.open("POST", "https://id.twitch.tv/oauth2/device");
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                callback(null, JSON.parse(xhr.responseText));
            } else {
                callback(xhr.responseText, null);
            }
        }
    }
    xhr.send("client_id=" + CLIENT_ID + "&scopes=user:read:follows");
}

function checkDeviceToken(deviceCode, callback) {
    let xhr = new XMLHttpRequest();
    xhr.open("POST", "https://id.twitch.tv/oauth2/token");
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            let res = {};
            try {
                res = JSON.parse(xhr.responseText);
            } catch (e) {
                callback("Error on Twitch response (Status: " + xhr.status + ")", null);
                return;
            }

            if (xhr.status === 200) {
                // Sucesso absoluto!
                callback(null, res);
            } else {
                // Pega a mensagem de erro da Twitch, seja na chave "message" ou "error"
                let errorStr = res.message || res.error || "Unknown error";

                if (errorStr === "authorization_pending") {
                    callback("pending", null);
                } else {
                    callback(errorStr, null);
                }
            }
        }
    }
    // Removido o "&scopes=..." desta etapa, pois ele não é permitido aqui!
    xhr.send("client_id=" + CLIENT_ID + "&device_code=" + deviceCode + "&grant_type=urn:ietf:params:oauth:grant-type:device_code");
}

function fetchUserInfo(token, callback) {
    let xhr = new XMLHttpRequest();
    xhr.open("GET", "https://api.twitch.tv/helix/users");
    xhr.setRequestHeader("Client-Id", CLIENT_ID);
    xhr.setRequestHeader("Authorization", "Bearer " + token);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) callback(null, JSON.parse(xhr.responseText));
            else callback(xhr.status, null);
        }
    }
    xhr.send();
}
