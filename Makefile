
BOOTED_DEVICE=$(shell xcrun simctl list | grep Booted | sed -n 1p)
MSG_FMT=\
{	\
	"Simulator Target Bundle": "net.chanify.ios",	\
	"aps": {	\
		"mutable-content" : 1,	\
		"alert": {	\
			"body": "$(text)"	\
		}	\
	}	\
}

apns:
	@echo '${MSG_FMT}' | xcrun simctl push `echo "${BOOTED_DEVICE}" | sed 's/\([^(]*\)(\([0-9A-F-]*\))\(.*\)/\2/g'` -

.PHONY: apns
