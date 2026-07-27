.pragma library

// ============================================================================
// streamlink.js
//
// Funções puras para montar os comandos de shell usados para:
//   - verificar se o "streamlink" está instalado
//   - detectar players de mídia comuns instalados no sistema
//   - montar o comando final "streamlink <url> <quality> --player <player> ..."
//
// A EXECUÇÃO real desses comandos é feita por um componente QML
// (StreamlinkRunner.qml) usando Plasma5Support.DataSource com engine
// "executable", já que QML puro não tem acesso a QProcess. Este arquivo só
// contém a lógica de montagem de comandos e é facilmente testável.
// ============================================================================

var KNOWN_PLAYERS = ["mpv", "vlc", "celluloid", "haruna", "smplayer"]

/**
 * Comando para checar se o streamlink está disponível no PATH.
 * Uso: rodar via DataSource "executable"; exit code 0 = disponível.
 */
function checkStreamlinkAvailableCommand() {
    return "command -v streamlink >/dev/null 2>&1 && echo OK || echo MISSING"
}

/**
 * Comando que testa, em sequência, cada player conhecido via "command -v".
 * Retorna uma lista de comandos "which"-like; o chamador (QML) deve rodar
 * cada um e agregar os resultados, OU usar buildDetectAllPlayersCommand()
 * abaixo para fazer tudo em uma única chamada de shell.
 */
function buildDetectAllPlayersCommand() {
    // Imprime uma linha por player encontrado, ex.: "mpv:/usr/bin/mpv"
    var parts = KNOWN_PLAYERS.map(function (p) {
        return "command -v " + p + " >/dev/null 2>&1 && echo " + p + ":$(command -v " + p + ")"
    })
    return parts.join("; ")
}

/**
 * Faz o parse da saída de buildDetectAllPlayersCommand() em uma lista de
 * objetos { name, path }.
 */
function parseDetectedPlayers(stdout) {
    var players = []
    if (!stdout) return players
        var lines = stdout.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line) continue
                var idx = line.indexOf(":")
                if (idx === -1) continue
                    players.push({
                        name: line.substring(0, idx),
                                 path: line.substring(idx + 1)
                    })
        }
        return players
}

function shellEscape(str) {
    return "'" + String(str).replace(/'/g, "'\\''") + "'"
}

/**
 * Monta o comando final para abrir um canal via streamlink.
 *
 * @param {string} channelLogin    login do canal (ex.: "shroud")
 * @param {string} quality         ex.: "best", "720p"
 * @param {string} playerPath      caminho do executável do player (mpv, vlc, ...)
 * @param {string} extraArgs       argumentos extras opcionais, já formatados
 */
function buildStreamlinkCommand(channelLogin, quality, playerPath, extraArgs) {
    var args = [
        "streamlink",
        "--player", shellEscape(playerPath),
        "https://twitch.tv/" + channelLogin,
        quality || "best"
    ]
    if (extraArgs && extraArgs.trim().length > 0) {
        args.push(extraArgs.trim())
    }
    return args.join(" ")
}

/**
 * URL da documentação de instalação do streamlink, usada no aviso da UI
 * quando o comando não é encontrado no PATH.
 */
var STREAMLINK_INSTALL_URL = "https://streamlink.github.io/install.html"
