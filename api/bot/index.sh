## use extglob in case statement
shopt -s extglob

## twitch like emotes
declare -A twitch=(
	[PogChamp]="CAADAQADMwcAAsTJswOVakNX-eTErBYE"
	[Kappa]="CAADAQADEQcAAsTJswOwrIcn0_a7ixYE"
	[4Head]="CAADAQADEwcAAsTJswP8QrR3rJSgRBYE"
	[LUL]="CAADAQADKQcAAsTJswMfEVJbyr4KCRYE"
	[FailFish]="CAADAQADGwcAAsTJswMrbQxZv1lXCRYE"
)

## Chat message about availables Emotes
emotes_list="*A list of availables Emotes:*"$'\n'
for emote in ${!twitch[@]}; do
	emotes_list+="- ${emote}"$'\n'
done

## irc like actions - /me
declare -A irc=(
	[hide]="CgADBAADH58AAjcYZAe93ngRN_RvJRYE"
	[confused]="CgADBAADqJ4AApcXZAfLn6iLIMIqGxYE"
)

source_button='[[{"text":"Source Code","url":"https://github.com/UserUnavailable/raqui333bot/blob/master/api/bot/index.sh"},
                 {"text":"GitHub","url":"https://github.com/UserUnavailable"}]]'

function send_msg {
	case ${1} in
		--sticker) curl -s -F "chat_id=${2}"                            \
			           -F "sticker=${3}"                            \
				   -F "reply_to_message_id=${4:-null}"          \
			   	   -X POST ${BOT}/sendSticker
			   	   ;;

		--animate) curl -s -F "chat_id=${2}"                            \
				   -F "animation=${3}"                          \
				   -F "reply_to_message_id=${4:-null}"          \
				   -X POST ${BOT}/sendAnimation
                                   ;;
		
		--button)  curl -s -F "chat_id=${2}"                            \
			           -F "text=${3}"                               \
				   -F "reply_markup={\"inline_keyboard\":${4}}" \
				   -F "reply_to_message_id=${5:-null}"          \
				   -F "parse_mode=Markdown"                     \
				   -F "disable_web_page_preview=true"           \
				   -X POST ${BOT}/sendMessage
				   ;;

		*)         curl -s -F "chat_id=${1}"                            \
			           -F "text=${2}"                               \
				   -F "reply_to_message_id=${3:-null}"          \
			           -F "parse_mode=Markdown"                     \
				   -F "disable_web_page_preview=true"           \
		   	           -X POST ${BOT}/sendMessage
			           ;;
   	esac
}

function send_base64 {
	## better understanding purpose
	## 1 is CHAT, 2 is TEXT, 4 is MSG_ID 

	local MSG_REPLY_TEXT=$(jq -r '.text' <<< ${3})
	local MSG_REPLY_ID=$(jq -r '.message_id' <<< ${3})
	
	if [[ ${MSG_REPLY_TEXT} != "null" ]];then
		if [[ $(awk '{print $2}' <<< ${2}) = "decode" ]];then
			send_msg ${1} "$(base64 -d <<< ${MSG_REPLY_TEXT} | tr -d '\n')" ${MSG_REPLY_ID}
		else
			send_msg ${1} "$(base64 <<< ${MSG_REPLY_TEXT} | tr -d '\n')" ${MSG_REPLY_ID}
		fi
	else
		send_msg ${1} "*Error*: that is not a text message."
	fi
}

function send_color {
	## 1 is CHAT, 2 is TEXT, 3 is MSG_REPLY_ID

	local color=$(grep -Eo '#\w+' <<< ${TEXT})
	
	if [[ ${color} ]];then
		if convert -size 512x512 xc:"${color}" /tmp/color.png;then
		        send_msg --sticker ${1} "@/tmp/color.png" ${3}
		else
			send_msg ${1} "*Error*: '${color}' is not a valid color."
		fi
	else
		send_msg ${1} "*Error*: no color found."
	fi
}

function send_irc {
	## 1 is CHAT, 2 is TEXT, 3 is MSG_REPLY_ID

	local cmd=$(awk '{print $2}' <<< ${2})
	
	if [[ ${cmd} ]];then
		for action in ${!irc[@]};do
			if [[ ${cmd} = ${action} ]];then
				send_msg --animate ${1} ${irc[${action}]} ${3}
				return
			fi	
		done

		## empty action handler
		send_msg ${1} "*Error*: no '${cmd}' action found."
	fi
}

handler() {
	http_response_json

	declare -g BOT="https://api.telegram.org/bot${TOKEN}"
	
	## Json data from POST entry
	local DATA=$(jq -r '.body' < $1)

	## local variables
	local TEXT=$(jq -r '.message.text' <<< ${DATA})
	local CHAT=$(jq -r '.message.chat.id' <<< ${DATA})
	local MSG_ID=$(jq -r '.message.message_id' <<< ${DATA})
	local MSG_REPLY_ID=$(jq -r '.message.reply_to_message.message_id // empty' <<< ${DATA})

	if [[ ${TEXT} =~ ^/ ]];then
		bot_command=$(awk '{print substr($1,2)}' <<< ${TEXT})
		case ${bot_command} in
			## /emotes - list of emotes
			emotes?(@Raqui333bot)) send_msg ${CHAT} "${emotes_list}" ${MSG_REPLY_ID:-${MSG_ID}}
					       ;;
			
			## /base64 - return a base64 string
			base64?(@Raqui333bot)) if REPLY=$(jq -re '.message.reply_to_message' <<< ${DATA});then
							send_base64 ${CHAT} "${TEXT}" "${REPLY}" ${MSG_ID}
					       else
							send_msg ${CHAT} "*Error*: please reply to a message."
					       fi
					       ;;
			
			## /source - link to the bot source
			source?(@Raqui333bot)) send_msg --button ${CHAT} "*This is my code and my owner's Github*:" "${source_button}" ${MSG_REPLY_ID:-${MSG_ID}}
					       ;;
			
			## /color - sends a hex color
			color?(@Raqui333bot)) send_color ${CHAT} "${TEXT}" ${MSG_REPLY_ID:-null}
					      ;;

			## /me - sed irc like actions
			me?(@Raqui333bot)) send_irc ${CHAT} "${TEXT}" ${MSG_REPLY_ID:-null}
                                           ;;

			## handler empty commands
			*) if [[ -z ${bot_command} ]];then
			   	send_msg ${CHAT} "Main Menu" ${MSG_ID}
			   fi
			   ;;
		esac
	fi

	## Twitch Emojis
	for emote in ${!twitch[@]}; do
		if [[ ${TEXT} =~ ${emote} ]]; then
			send_msg --sticker ${CHAT} ${twitch[${emote}]} ${MSG_REPLY_ID}
			break
		fi
	done

	http_response_code 200
}
