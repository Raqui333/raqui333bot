## use extglob in case statement
shopt -s extglob

declare -A twitch=(
	[PogChamp]="CAADAQADMwcAAsTJswOVakNX-eTErBYE"
	[Kappa]="CAADAQADEQcAAsTJswOwrIcn0_a7ixYE"
	[4Head]="CAADAQADEwcAAsTJswP8QrR3rJSgRBYE"
	[LUL]="CAADAQADKQcAAsTJswMfEVJbyr4KCRYE"
)

declare -A irc=(
	[hide]="CgADBAADH58AAjcYZAe93ngRN_RvJRYE"
)

source_button='[[{"text":"Source Code","url":"https://github.com/UserUnavailable/raqui333bot/blob/master/api/bot/index.sh"},
                 {"text":"GitHub","url":"https://github.com/UserUnavailable"}]]'

## Chat message about availables Emotes
emotes_list="*A list of availables Emotes:*"$'\n'
for emote in ${!twitch[@]}; do
	emotes_list+="- ${emote}"$'\n'
done

function send_msg() {
	case ${1} in
		--reply)   curl -s -F "chat_id=${2}"                            \
			           -F "text=${3}"                               \
				   -F "reply_to_message_id=${4}"                \
				   -F "parse_mode=Markdown"                     \
		          	   -X POST ${BOT}/sendMessage
			 	   ;;
		
		--sticker) curl -s -F "chat_id=${2}"                            \
			           -F "sticker=${3}"                            \
			   	   -X POST ${BOT}/sendSticker
			   	   ;;
		
		--button)  curl -s -F "chat_id=${2}"                            \
				   -F "text=${3}"                               \
				   -F "reply_markup={\"inline_keyboard\":${4}}" \
				   -F "reply_to_message_id=${5}"                \
				   -F "parse_mode=Markdown"                     \
			           -F "disable_web_page_preview=true"           \
				   -X POST ${BOT}/sendMessage
				   ;;

		--animate) curl -s -F "chat_id=${2}"                            \
				   -F "animation=${3}"                          \
				   -X POST ${BOT}/sendAnimation                 \
                                   ;;
		
		*)         curl -s -F "chat_id=${1}"                            \
			           -F "text=${2}"                               \
			           -F "parse_mode=Markdown"                     \
		   	           -X POST ${BOT}/sendMessage
			           ;;
   	esac
}

function send_base64() {
	## better understanding purpose
	## $1 is CHAT, $2 is MSG, $3 is REPLY and $4 id ID
	
	local REPLY_MSG=$(jq -r '.text' <<< ${3})
	local REPLY_ID=$(jq -r '.message_id' <<< ${3})
	
	if [[ ${REPLY_MSG} != "null" ]];then
		if [[ $(awk '{print $2}' <<< ${2}) = "decode" ]];then
			send_msg --reply ${1} "$(base64 -d <<< ${REPLY_MSG} | tr -d '\n')" ${REPLY_ID}
		else
			send_msg --reply ${1} "$(base64 <<< ${REPLY_MSG} | tr -d '\n')" ${REPLY_ID}
		fi
	else
		send_msg --reply ${1} "*Error*: that is not a text message." ${4}
	fi
}

function send_color() {
	## $1 is CHAT, $2 is MSG and $3 is ID	

	local color=$(grep -Eo '#\w+' <<< ${2})
	
	if [[ ${color} ]];then
		if convert -size 512x512 xc:"${color}" /tmp/color.png;then
		        send_msg --sticker ${1} "@/tmp/color.png"
		else
			send_msg --reply ${1} "*Error*: '${color}' is not a valid color." ${3}
		fi
	else
		send_msg --reply ${1} "*Error*: no color found." ${3}
	fi
}

function send_irc() {
	## $1 is CHAT, $2 is MSG

	local cmd=$(awk '{print $2}' <<< ${2})
	
	if [[ ${cmd} ]];then
		for action in ${!irc[@]};do
			if [[ ${cmd} = ${action} ]];then
				send_msg --animate ${1} ${irc[${action}]}
				return
			fi	
		done

		## handler empty action
		send_msg ${1} "*Error*: no '${cmd}' action found."
	fi
}

handler() {
	http_response_json

	BOT="https://api.telegram.org/bot${TOKEN}"
	DATA=$(jq -r '.body' < $1)

	MSG=$(jq -r '.message.text' <<< ${DATA})
	CHAT=$(jq -r '.message.chat.id' <<< ${DATA})
	ID=$(jq -r '.message.message_id' <<< ${DATA})

	if [[ ${MSG} =~ ^/ ]];then
		bot_command=$(awk '{print substr($1,2)}' <<< ${MSG})
		case ${bot_command} in
			## /emotes - list of emotes
			emotes?(@Raqui333bot)) send_msg ${CHAT} "${emotes_list}"
					       ;;
			
			## /base64 - return a base64 string
			base64?(@Raqui333bot)) if REPLY=$(jq -re '.message.reply_to_message' <<< ${DATA});then
							send_base64 ${CHAT} "${MSG}" "${REPLY}" ${ID}
					       else
							send_msg ${CHAT} "*Error*: please reply to a message."
					       fi
					       ;;
			
			## /source - link to the bot source
			source?(@Raqui333bot)) send_msg --button ${CHAT} "*This is my code and my owner's Github*:" "${source_button}" ${ID}
			                       ;;
			
			## /color - sends a hex color
			color?(@Raqui333bot)) send_color ${CHAT} "${MSG}" ${ID}
					      ;;

			## /me - sed irc like actions
			me?(@Raqui333bot)) send_irc ${CHAT} "${MSG}"
                                           ;;

			## handler empty commands
			*) if [[ -z ${bot_command} ]];then
			   	send_msg --reply ${CHAT} "Main Menu" ${ID}
			   fi
			   ;;
		esac
	fi

	## Twitch Emojis
	for emote in ${!twitch[@]}; do
		if [[ ${MSG} =~ ${emote} ]]; then
			send_msg --sticker ${CHAT} ${twitch[${emote}]}
			break
		fi
	done

	http_response_code 200
}
