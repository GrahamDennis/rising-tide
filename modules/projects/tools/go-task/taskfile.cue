#Command: string | {cmd: string, task?: _|_, defer?: _|_, ...} | {task: string, cmd?: _|_, defer?: _|_, ...} | {defer: #Command}
#Dependency: string | {task: string, ...}

#Task: {
	desc?: string
	deps?: [...#Dependency]
	cmds?: [...#Command]
	internal?: bool
	if (deps == _|_ && cmds == _|_) {internal: bool | *true}
	...
}

version: "3"

output?: string | {...}

tasks: [string]: #Task
