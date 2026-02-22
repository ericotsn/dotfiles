function uuid -d "Generate a UUID"
	if command -v uuidgen &>/dev/null
		uuidgen | tr "[:upper:]" "[:lower:]"
		return 0
	end

	if command -v python3 &>/dev/null
		python3 -c "import uuid; print(uuid.uuid4())"
		return 0
	end

	if command -v node &>/dev/null
		node -e "console.log(require('crypto').randomUUID())"
		return 0
	end

	set_color red
	echo "Error: No UUID generator available (tried uuidgen, python3, node)"
	set_color normal
	return 1
end
