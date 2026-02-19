Manage one-time reminders. Run the appropriate command inside the Docker container based on the argument: $ARGUMENTS

Commands:
- `done <id>` — Mark a reminder as done
- `list` — Show all reminders with status
- `add "text"` — Add a new reminder
- `add "text" YYYY-MM-DD` — Add a reminder that starts on a specific date
- (no args) — Show all reminders

Examples:
- `/reminder list`
- `/reminder done mailbox-key`
- `/reminder add "Cancel old subscription"`
- `/reminder add "Renew domain" 2025-03-01`

Run the command:
```
docker exec maxassist /maxassist/scripts/reminders.sh $ARGUMENTS
```

If no arguments are provided, default to `list`.

Show the output to the user.
