import "list"

import "encoding/yaml"

header: {...}
#LanguageSection: {...}
languages: [Name=string]: #LanguageSection & {
	Language: Name
}

sections: list.Concat([[header], [for name, section in languages {section}]])

rendered: yaml.MarshalStream(sections)
