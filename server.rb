`killall sc-ruby`
Process.fork do
	$0 = 'sc-ruby';
	`cd ~/sclang; mkfifo scpipe; tail -f ~/sclang/scpipe | sclang -d ~/sclang/ > ~/sclang/supercollider.log`
end
