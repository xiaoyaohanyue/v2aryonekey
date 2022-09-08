_get_latest_version() {
	xray_repos_url="https://api.github.com/repos/XTLS/Xray-core/releases/latest?v=$RANDOM"
	xray_latest_ver="$(curl -s $xray_repos_url | grep 'tag_name' | cut -d\" -f4)"

	if [[ ! $xray_latest_ver ]]; then
		echo
		echo -e " $red获取 xray 最新版本失败!!!$none"
		echo
		echo -e " 请尝试执行如下命令: $green echo 'nameserver 8.8.8.8' >/etc/resolv.conf $none"
		echo
		echo " 然后再重新运行脚本...."
		echo
		exit 1
	fi
}

_download_xray_file() {
	[[ ! $xray_latest_ver ]] && _get_latest_version
	xray_tmp_file="/tmp/xray.zip"
	xray_download_link="https://github.com/v2fly/xray-core/releases/download/$xray_latest_ver/xray-linux-${v2ray_bit}.zip"

	if ! wget --no-check-certificate -O "$xray_tmp_file" $xray_download_link; then
		echo -e "
        $red 下载 xray 失败啦..可能是你的 VPS 网络太辣鸡了...请重试...$none
        " && exit 1
	fi

	unzip -o $xray_tmp_file -d "/usr/bin/xray/"
	chmod +x /usr/bin/xray/xray
	if [[ ! $(cat /root/.bashrc | grep xray) ]]; then
		echo "alias xray=$_v2ray_sh" >>/root/.bashrc
	fi
}

_install_xray_service() {
	# cp -f "/usr/bin/xray/systemd/xray.service" "/lib/systemd/system/"
	# sed -i "s/on-failure/always/" /lib/systemd/system/xray.service
	cat >/lib/systemd/system/xray.service <<-EOF
[Unit]
Description=xray Service
Documentation=https://www.xray.com/ https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
# If the version of systemd is 240 or above, then uncommenting Type=exec and commenting out Type=simple
#Type=exec
Type=simple
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=nobody and commenting out User=root, the service will run as user nobody.
# More discussion at https://github.com/xray/xray-core/issues/1011
User=root
#User=nobody
Environment="XRAY_VMESS_AEAD_FORCED=false"
#CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/env xray.vmess.aead.forced=false /usr/bin/xray/xray run -config /etc/xray/config.json
#Restart=on-failure
Restart=always

[Install]
WantedBy=multi-user.target
EOF
	systemctl enable xray
}

_update_xray_version() {
	_get_latest_version
	if [[ $v2ray_ver != $xray_latest_ver ]]; then
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		_download_xray_file
		do_service restart xray
		echo
		echo -e " $green 更新成功啦...当前 xray 版本: ${cyan}$xray_latest_ver$none"
		echo
		echo -e " $yellow 温馨提示: 为了避免出现莫名其妙的问题...xray 客户端的版本最好和服务器的版本保持一致$none"
		echo
	else
		echo
		echo -e " $green 木有发现新版本....$none"
		echo
	fi
}

_mkdir_dir() {
	mkdir -p /var/log/xray
	mkdir -p /etc/xray
}
