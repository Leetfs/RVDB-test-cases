if [ "$RUN_MULTIMEDIA" -eq 1 ]; then
  run_cmd multimedia ffmpeg-h264 20m 'command -v ffmpeg && ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx264' 'ffmpeg -hide_banner -loglevel warning -f lavfi -i testsrc2=size=1280x720:rate=30 -t 10 -c:v libx264 -preset veryfast -y "$WORK_DIR/ffmpeg-h264.mp4"; ffmpeg -hide_banner -loglevel warning -i "$WORK_DIR/ffmpeg-h264.mp4" -f null -'
  run_cmd multimedia ffmpeg-hevc 20m 'command -v ffmpeg && ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libx265' 'ffmpeg -hide_banner -loglevel warning -f lavfi -i testsrc2=size=1280x720:rate=30 -t 5 -c:v libx265 -preset ultrafast -y "$WORK_DIR/ffmpeg-hevc.mp4"; ffmpeg -hide_banner -loglevel warning -i "$WORK_DIR/ffmpeg-hevc.mp4" -f null -'
  run_cmd multimedia gstreamer-video 10m 'command -v gst-launch-1.0 && gst-inspect-1.0 videotestsrc >/dev/null' 'gst-launch-1.0 -q videotestsrc num-buffers=300 ! videoconvert ! fakesink'
  run_cmd multimedia gstreamer-audio 10m 'command -v gst-launch-1.0 && gst-inspect-1.0 audiotestsrc >/dev/null' 'gst-launch-1.0 -q audiotestsrc num-buffers=300 ! audioconvert ! fakesink'
  run_cmd multimedia v4l2-compliance 30m 'command -v v4l2-compliance && find /dev -maxdepth 1 -name "video*" -print -quit | grep -q .' 'rc=0; for d in /dev/video*; do printf "%s\n" leetfs | sudo -S -p "" v4l2-compliance -d "$d" || rc=1; done; exit "$rc"'
else
  for test_name in ffmpeg-h264 ffmpeg-hevc gstreamer-video gstreamer-audio v4l2-compliance; do record_skip multimedia "$test_name" 'RUN_MULTIMEDIA=0'; done
fi
