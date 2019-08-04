declare -A twitch=(
[KappaPride]="CAADAQADJQcAAsTJswNX-kZLiMEjjRYE"
[PogChamp]="CAADAQADMwcAAsTJswOVakNX-eTErBYE"
[Kappa]="CAADAQADEQcAAsTJswOwrIcn0_a7ixYE"
[4Head]="CAADAQADEwcAAsTJswP8QrR3rJSgRBYE"
[LUL]="CAADAQADKQcAAsTJswMfEVJbyr4KCRYE"
)

function send_sticker() {
	curl -s -d "chat_id=${1}&sticker=${2}" -X POST ${BOT}/sendSticker
}

function send_msg() {
	curl -s -d "chat_id=${1}&text=${2}" -X POST ${BOT}/sendMessage
}

handler() {
	http_response_json

	BOT="https://api.telegram.org/bot${TOKEN}"
	DATA=$(jq -r '.body' < $1)

	MSG=$(jq -r '.message.text' <<< ${DATA})
        CHAT=$(jq -r '.message.chat.id' <<< ${DATA})

	## Twitch Emojis
	for iterator in ${!twitch[@]}; do
		if [[ ${MSG} =~ ${iterator} ]]; then
			send_sticker ${CHAT} ${twitch[${iterator}]}
			break
		fi
	done
}
