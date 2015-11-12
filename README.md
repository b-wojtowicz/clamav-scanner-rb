# clamav-scanner-rb
Scans your server using (ClamAV) and sends HipChat notifications with summary

Run scanner:
```
AVSCAN_LOG_FILE=/home/user/avscan.log AVSCAN_HIPCHAT_ROOM_ID=your-room-id AVSCAN_HIPCHAT_ROOM_TOKEN=your-notification-token ruby avscan.rb
```
