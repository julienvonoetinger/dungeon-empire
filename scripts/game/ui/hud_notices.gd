extends RefCounted
## Display-only French wording for simulator messages restored from v1.0.0
## (some English, some without accents). The simulator text, its rules and the
## saves are untouched; unknown messages pass through unchanged.
const EXACT := {
	"Choose an anchoring site for the Dungeon Core.": "Choisissez où ancrer le cœur.",
	"The Core must anchor inside the marked influence field.": "Le cœur doit être ancré dans la zone marquée.",
	"Le coeur s'eveille. Son passage peripherique est gratuit. Creusez depuis cette salle.": "Le cœur s’éveille. Son passage périphérique est gratuit. Creusez depuis cette salle.",
	"Entree replacee contre une paroi.": "Entrée replacée contre une paroi.",
	"Ancienne entree retiree : placez gratuitement une entree contre une paroi.": "Ancienne entrée retirée : placez gratuitement une entrée contre une paroi.",
	"No tile under the cursor.": "Aucune case ici.",
	"The entrance and the Core cannot be modified.": "L’entrée et le cœur ne peuvent pas être modifiés.",
	"Structure cleared.": "Structure retirée.",
	"Placez le coffre sur une case excavee.": "Placez le coffre sur une case creusée.",
	"Ce coffre possede deja cette protection ou une protection superieure.": "Ce coffre possède déjà cette protection ou une meilleure.",
	"Coffre ameliore.": "Coffre amélioré.",
	"Coffre installe.": "Coffre installé.",
	"Protection du coffre restauree.": "Protection du coffre restaurée.",
	"Cette case n'est pas un rocher.": "Cette case n’est pas de la roche.",
	"Ce rocher soutient l'entree.": "Cette roche soutient l’entrée.",
	"You must dig from an existing passage.": "Creusez depuis un passage existant.",
	"Dug a passage.": "Passage creusé.",
	"Le passage autour du coeur doit rester libre : placez l'entree plus loin.": "Le passage autour du cœur doit rester libre : placez l’entrée plus loin.",
	"The entrance stair is already set. It cannot be moved.": "L’escalier d’entrée est déjà placé et ne peut pas être déplacé.",
	"Placez l'entree contre une paroi, avec un passage libre devant.": "Placez l’entrée contre une paroi, avec un passage libre devant.",
	"Entrance opened. Build enough storage before heroes can find it.": "Entrée ouverte. Construisez assez de coffres avant l’arrivée des aventuriers.",
	"Dig this passage first.": "Creusez d’abord ce passage.",
	"Le passage autour du coeur doit rester libre.": "Le passage autour du cœur doit rester libre.",
	"A door must sit in a gap between two walls.": "Une porte se place dans une ouverture entre deux murs.",
	"Nothing to repair (or not enough gold).": "Rien à réparer (ou or insuffisant).",
}
const PATTERNS := [
	["^Not enough gold \\((\\d+) required\\)\\.$", "Or insuffisant : {0} requis."],
	["^Not enough gold to dig \\((\\d+)\\)\\.$", "Or insuffisant pour creuser : {0} requis."],
	["^Entrance opened\\. Heroes will find it in (\\d+)s\\.$", "Entrée ouverte. Les aventuriers la trouveront dans {0} s."],
	["^Repairs: (\\d+) door\\(s\\), (\\d+) trap charge\\(s\\)\\.$", "Réparations : {0} porte(s), {1} charge(s) de piège."],
]
static var _compiled: Array = []

static func french(text: String) -> String:
	if EXACT.has(text): return EXACT[text]
	if _compiled.is_empty():
		for pair in PATTERNS:
			var expression := RegEx.new(); expression.compile(pair[0])
			_compiled.append([expression,pair[1]])
	for pair in _compiled:
		var found: RegExMatch = pair[0].search(text)
		if found:
			var values := []
			for index in range(1,found.get_group_count()+1): values.append(found.get_string(index))
			return String(pair[1]).format(values)
	return text
