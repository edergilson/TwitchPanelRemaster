import QtQuick 2.15
import org.kde.plasma.plasma5support 2.0 as Plasma5Support

/*
 * StreamlinkRunner
 * ----------------
 * Executa comandos de shell relacionados ao streamlink (checar
 * disponibilidade, detectar players, abrir uma stream) usando
 * Plasma5Support.DataSource com engine "executable" — a forma padrão e
 * suportada de rodar processos externos a partir de um plasmoid QML.
 */
Item {
    id: root

    property var _pending: ({})

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function (sourceName, data) {
            var cb = root._pending[sourceName]
            delete root._pending[sourceName]
            disconnectSource(sourceName)
            if (!cb) return

                var exitCode = data["exit code"]
                var stdout = (data["stdout"] || "").toString()
                var stderr = (data["stderr"] || "").toString()

                if (cb.onResult) {
                    cb.onResult(exitCode, stdout, stderr)
                }
        }
    }

    /**
     * Roda um comando de shell arbitrário. callbacks: { onResult(exitCode, stdout, stderr) }
     * Comandos de "abrir player" são disparados de forma "fire and forget":
     * não esperamos o processo terminar (streamlink/mpv ficam abertos), então
     * o exit code refletirá apenas o lançamento do processo em background.
     */
    function run(command, callbacks, background) {
        var finalCmd = background ? (command + " >/dev/null 2>&1 &") : command
        root._pending[finalCmd] = callbacks || {}
        executable.connectSource(finalCmd)
    }
}
