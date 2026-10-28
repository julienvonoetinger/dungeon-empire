extends SceneTree
const Runner = preload("res://scripts/testing/scenario_runner.gd")
const DEFAULT_SUITE := "res://tests/scenarios"
var report_path := "res://artifacts/probes/report.json"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var options := {}
	var error := ""
	var index := 0
	while index < args.size():
		var key := args[index]
		if key not in ["--scenario","--suite","--seed","--runs","--report"] or options.has(key) or index+1 >= args.size():
			error = "Invalid/duplicate option or missing value: " + key
			break
		options[key] = args[index+1]
		index += 2
	if options.has("--report"): report_path = options["--report"]
	if report_path.begins_with("user://") or report_path.get_extension().to_lower() != "json":
		print("Report must be a .json file outside user://")
		quit(2)
		return
	if options.has("--scenario") and options.has("--suite"): error = "Choose --scenario OR --suite"
	for key in ["--seed","--runs"]:
		if options.has(key) and not str(options[key]).is_valid_int(): error = key + " must be an integer"
	var runs := int(options.get("--runs","1"))
	if runs < 1 or runs > 100: error = "--runs must be between 1 and 100"
	if options.has("--seed") and (absf(float(options["--seed"]))+runs-1 > 2147483647): error = "Seed outside signed 32-bit range"
	var paths: Array[String] = []
	if options.has("--scenario"):
		paths.append(options["--scenario"])
	else:
		var directory: String = options.get("--suite",DEFAULT_SUITE)
		var dir := DirAccess.open(directory)
		if dir == null: error = "Cannot read suite: " + directory
		else:
			for file in dir.get_files():
				if file.ends_with(".json"): paths.append(directory.path_join(file))
			paths.sort()
	if paths.is_empty() or paths.size() > 64: error = "Suite must contain 1..64 JSON files"
	# A conflicting output path must not receive even an error report. Do this
	# independently of validation, including when another input was malformed.
	for path in paths:
		if _canonical(path) == _canonical(report_path):
			print("Report would overwrite input scenario; nothing written")
			quit(2)
			return
	if not options.has("--scenario") and _canonical(report_path.get_base_dir()) == _canonical(options.get("--suite",DEFAULT_SUITE)):
		print("Keep reports outside the input suite; nothing written")
		quit(2)
		return
	var runner := Runner.new()
	var scenarios: Array[Dictionary] = []
	if error.is_empty():
		for path in paths:
			var file := FileAccess.open(path,FileAccess.READ)
			if file == null or file.get_length() > 1048576:
				error = "Missing/unreadable/oversized scenario: " + path
				break
			var parser := JSON.new()
			var parse_error := parser.parse(file.get_as_text())
			file.close()
			if parse_error != OK:
				error = "%s:%d: %s" % [path,parser.get_error_line(),parser.get_error_message()]
				break
			var validation := runner.validate(parser.data)
			if not validation.get("ok",false):
				error = path + ": " + "; ".join(validation.get("errors",["Validation did not complete"]))
				break
			var data: Dictionary = parser.data
			if absf(float(options.get("--seed",data.get("seed",1))))+runs-1 > 2147483647:
				error = "Seed range overflow"
				break
			scenarios.append({"path":path,"data":data})
	var report := {"version":1,"ok":false,"status":"error","runs":[],"error":error}
	var exit_code := 2
	if error.is_empty():
		exit_code = 0
		for entry in scenarios:
			for repetition in runs:
				var data: Dictionary = entry.data.duplicate(true)
				data.seed = int(options.get("--seed",data.get("seed",1))) + repetition
				var result := runner.run(data,root)
				result["source"] = entry.path
				report.runs.append(result)
				if not result.ok: exit_code = 1
				print("%s | %s | seed=%d | ticks=%d | failures=%d" % [result.status,result.name,result.seed,result.ticks,result.failures.size()])
		report.ok = exit_code == 0
		report.status = "passed" if report.ok else "failed"
	else: print(error)
	var absolute := ProjectSettings.globalize_path(report_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		print("Cannot create report directory")
		quit(2)
		return
	var output := FileAccess.open(absolute,FileAccess.WRITE)
	if output == null:
		print("Cannot write report: ",absolute)
		quit(2)
		return
	output.store_string(JSON.stringify(report,"\t",true)+"\n")
	output.flush()
	if output.get_error() != OK: exit_code = 2
	output.close()
	print("Report: ",absolute)
	quit(exit_code)

func _canonical(path: String) -> String:
	var absolute := ProjectSettings.globalize_path(path).replace("\\","/")
	if not absolute.is_absolute_path(): absolute = DirAccess.open(".").get_current_dir().path_join(absolute)
	absolute = absolute.simplify_path()
	return absolute.to_lower() if OS.get_name() == "Windows" else absolute
