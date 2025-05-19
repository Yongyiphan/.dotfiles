from discordrp import Presence
import time

client_id_pc = "1131590583832563804"

with Presence(client_id_pc) as presence:
    presence.set(
        {
            "state": "In Game",
            "details": "Kek",
            "timestamps": {"start", int(time.time())},
        }
    )
    while True:
        time.sleep(15)
