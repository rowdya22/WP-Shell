# WP-Shell
WP-CLI wrapper and other bash WordPress tools to alleviate frustration and get the job done

```
source /dev/stdin <<< "$(curl https://raw.githubusercontent.com/rowdya22/WP-Shell/refs/heads/main/wpshell.sh)";
```

TO DO:
- Color Alerts for not optimal values.
- Adjust Columns in `wpstats` so SITE TESTS share the same line. Further condence as needed.
- Remove dispaly of "WP-CLI CHECL: [OK]" when `wpshell` is run.
- Color Code DB Conn Status.
- Detect and alert for EMPTY_TRASH_DAYS
- Add `sucuri-integrity.php` exclusions. Default and custom options.
- Possibly add database size, file size, and file count to `wpstats`. Ensure calculations are not run each calling of `wpstats`.
