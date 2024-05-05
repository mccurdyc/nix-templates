package config

stages: [StageName=string]: #Stage & {
	name: StageName

	regions: [RegionName=string]: #Region & {
		name: RegionName

    xxx: input: value: "global across envs config"
	}
}
