## use extglob in case statement
shopt -s extglob

declare -A twitch=(
	[KappaPride]="CAADAQADJQcAAsTJswNX-kZLiMEjjRYE"
	[PogChamp]="CAADAQADMwcAAsTJswOVakNX-eTErBYE"
	[Kappa]="CAADAQADEQcAAsTJswOwrIcn0_a7ixYE"
	[4Head]="CAADAQADEwcAAsTJswP8QrR3rJSgRBYE"
	[LUL]="CAADAQADKQcAAsTJswMfEVJbyr4KCRYE"
)

## Chat message about availables Emotes
emotes_list="*A list of availables Emotes:*"$'\n'
for emote in ${!twitch[@]}; do
	emotes_list+="- ${emote}"$'\n'
done

function send_msg() {
	case ${1} in
		--reply)   curl -s -F "chat_id=${2}"             \
			           -F "text=${3}"                \
				   -F "parse_mode=Markdown"      \
				   -F "reply_to_message_id=${4}" \
		          	   -X POST ${BOT}/sendMessage
			 	   ;;
		
		--sticker) curl -s -F "chat_id=${2}"             \
			           -F "sticker=${3}"             \
			   	   -X POST ${BOT}/sendSticker
			   	   ;;
		
		*)         curl -s -F "chat_id=${1}"             \
			           -F "text=${2}"                \
			           -F "parse_mode=Markdown"      \
		   	           -X POST ${BOT}/sendMessage
			           ;;
   	esac
}

function send_base64() {
	## better understanding purpose
	## $1 is CHAT, $2 is MSG and $3 is REPLY

	local REPLY_MSG=$(jq -r '.text' <<< ${3})
	local REPLY_ID=$(jq -r '.message_id' <<< ${3})

	if [[ $(awk '{print $2}' <<< ${2}) = "decode" ]];then
		send_msg --reply ${1} "$(base64 -d <<< ${REPLY_MSG})" ${REPLY_ID}
	else
		send_msg --reply ${1} "$(base64 <<< ${REPLY_MSG})" ${REPLY_ID}
	fi
}

handler() {
	http_response_json

	BOT="https://api.telegram.org/bot${TOKEN}"
	DATA=$(jq -r '.body' < $1)

	MSG=$(jq -r '.message.text' <<< ${DATA})
	CHAT=$(jq -r '.message.chat.id' <<< ${DATA})

	if [[ ${MSG} =~ ^/ ]];then
		case $(awk '{print substr($1,2)}' <<< ${MSG}) in
			## /emotes - list of emotes
			emotes?(@Raqui333bot)) send_msg ${CHAT} "${emotes_list}"
					       ;;
			
			## /base64 - return a base64 string
			base64?(@Raqui333bot)) if REPLY=$(jq -re '.message.reply_to_message' <<< ${DATA});then
							send_base64 ${CHAT} "${MSG}" "${REPLY}"
					       else
							send_msg ${CHAT} "*Error*: please reply to a message."
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
