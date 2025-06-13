const axios = require('axios');
const cron = require('node-cron');
const _ = require('underscore');
const fs = require('fs');
const config = require('./config.json');
const wclurl = `https://www.warcraftlogs.com/v1/reports/user/${config.wclUserId}?api_key=${config.wclApiKey}&start=1743532800000`;
const discordurl = "https://discord.com/api/webhooks/1382732249598001245/UBma6cw-cPv8aANWUlfvEE0AjzwuuCwr3ovqNHnH3V9HEB3QaZ1iyy5pZu3W4H2fTlMJ";

// 2025-05-01 00:00:00 UTC timestamp in milliseconds
const START_DATE = 1743532800000;

// Load sent logs from file or initialize empty array
let sentLogs = [];
try {
    sentLogs = JSON.parse(fs.readFileSync('sent_logs.json'));
} catch (err) {
    fs.writeFileSync('sent_logs.json', JSON.stringify([]));
}

// Track no new logs count and search message status
let noNewLogsCount = 0; // For fast mode
let noNewLogsSlowModeCount = 0; // For slow mode
let isSlowMode = false;
let isSilentMode = false;
let hasSentInitialSearchMessage = false;
let cronJob;

// Send startup message to Discord
axios.post(discordurl, { content: '[Logs上傳助手已啟動]' })
    .then(() => console.log('Sent startup message: [Logs上傳助手已啟動]'))
    .catch(err => console.error('Discord Startup Error:', err.message));

// Start cron job with 5-second interval
cronJob = cron.schedule('*/5 * * * * *', () => {
    if (!isSilentMode && !hasSentInitialSearchMessage) {
        axios.post(discordurl, { content: '[開始進行是否有新的Logs紀錄檢索]' })
            .then(() => {
                console.log('Sent message: [開始進行是否有新的Logs紀錄檢索]');
                hasSentInitialSearchMessage = true;
            })
            .catch(err => console.error('Discord Error:', err.message));
    }
    
    axios.get(wclurl)
        .then(response => {
            update(response.data);
        })
        .catch(err => console.error('API Error:', err.message));
});

// Update function to handle logs and mode switching
function update(body) {
    const newLogs = body.filter(log => log.start >= START_DATE && !sentLogs.includes(log.id));
    
    if (newLogs.length > 0) {
        // Reset counts and modes
        noNewLogsCount = 0;
        noNewLogsSlowModeCount = 0;
        isSilentMode = false;
        if (isSlowMode) {
            isSlowMode = false;
            hasSentInitialSearchMessage = false; // Allow search message on next fast mode search
            cronJob.stop();
            cronJob = cron.schedule('*/5 * * * * *', () => {
                if (!isSilentMode && !hasSentInitialSearchMessage) {
                    axios.post(discordurl, { content: '[開始進行是否有新的Logs紀錄檢索]' })
                        .then(() => {
                            console.log('Sent message: [開始進行是否有新的Logs紀錄檢索]');
                            hasSentInitialSearchMessage = true;
                        })
                        .catch(err => console.error('Discord Error:', err.message));
                }
                axios.get(wclurl)
                    .then(response => update(response.data))
                    .catch(err => console.error('API Error:', err.message));
            });
            axios.post(discordurl, { content: '[恢復快速模式 5 秒進行一次檢索]' })
                .then(() => console.log('Sent message: [恢復快速模式 5 秒進行一次檢索]'))
                .catch(err => console.error('Discord Error:', err.message));
        }

        // Process new logs
        newLogs.forEach(log => {
            const string = `New log: ${log.title} (${log.owner}) -- https://www.warcraftlogs.com/reports/${log.id}`;
            
            sentLogs.push(log.id);
            axios.post(discordurl, { content: string })
                .then(() => console.log(string))
                .catch(err => console.error('Discord Error:', err.message));
            
            // Save sent logs to file
            fs.writeFileSync('sent_logs.json', JSON.stringify(sentLogs));
        });
    } else {
        // Handle no new logs
        console.log('No new logs since 2025-05-01');
        
        if (!isSlowMode) {
            // Fast mode: increment fast mode count
            noNewLogsCount++;
            if (noNewLogsCount >= 3) {
                isSlowMode = true;
                hasSentInitialSearchMessage = false; // Allow search message on next slow mode search
                cronJob.stop();
                axios.post(discordurl, { content: '[目前沒有新的Logs紀錄]' })
                    .then(() => {
                        console.log('Sent message: [目前沒有新的Logs紀錄]');
                        axios.post(discordurl, { content: '[現在為慢速模式 5 分鐘進行一次檢索]' })
                            .then(() => console.log('Sent message: [現在為慢速模式 5 分鐘進行一次檢索]'))
                            .catch(err => console.error('Discord Error:', err.message));
                    })
                    .catch(err => console.error('Discord Error:', err.message));
                cronJob = cron.schedule('0 */5 * * * *', () => {
                    if (!isSilentMode && !hasSentInitialSearchMessage) {
                        axios.post(discordurl, { content: '[開始進行是否有新的Logs紀錄檢索]' })
                            .then(() => {
                                console.log('Sent message: [開始進行是否有新的Logs紀錄檢索]');
                                hasSentInitialSearchMessage = true;
                            })
                            .catch(err => console.error('Discord Error:', err.message));
                    }
                    axios.get(wclurl)
                        .then(response => update(response.data))
                        .catch(err => console.error('API Error:', err.message));
                });
            }
        } else {
            // Slow mode: increment slow mode count
            noNewLogsSlowModeCount++;
            if (noNewLogsSlowModeCount >= 2 && !isSilentMode) {
                isSilentMode = true;
                console.log('Entering silent mode: no further notifications until new logs are found.');
            }
        }
    }
}

// Handle program termination
process.on('SIGINT', () => {
    axios.post(discordurl, { content: '[Logs上傳助手關閉]' })
        .then(() => {
            console.log('Sent shutdown message: [Logs上傳助手關閉]');
            process.exit(0);
        })
        .catch(err => {
            console.error('Discord Shutdown Error:', err.message);
            process.exit(1);
        });
});