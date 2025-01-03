version: "3"

#Command: string | { cmd: string, task?: _|_, ... } | { task: string, cmd?: _|_, ... }
#Dependency: string | { task: string, ... }

#Task: {
    desc?: string
    deps?: [...#Dependency]
    cmds?: [...#Command]
    internal?: bool
    if (deps == _|_ && cmds == _|_) {internal: bool | *true}
    ...
}

tasks: [string]: #Task

tasks: {
	test: desc: "Run all tests"
	check: { desc: "Run all checks", aliases: ["lint", "format", "fmt"] }
}
