#define _GNU_SOURCE
#include <errno.h>
#include <gpiod.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>

#define TEMP_PATH "/sys/class/hwmon/hwmon0/temp1_input"
#define HUM_PATH  "/sys/class/hwmon/hwmon0/humidity1_input"

static volatile sig_atomic_t running = 1;
static void on_sig(int s) { (void)s; running = 0; }

static void print_sht31(void)
{
    int t = 0, h = 0;
    FILE *ft = fopen(TEMP_PATH, "r"), *fh = fopen(HUM_PATH, "r");
    if (ft && fh && fscanf(ft, "%d", &t) == 1 && fscanf(fh, "%d", &h) == 1) {
        double c = t / 1000.0;
        printf("[SHT31] Temp: %.2f C (%.2f F) | Humidity: %.2f %%RH\n",
               c, c * 9.0 / 5.0 + 32.0, h / 1000.0);
    }
    if (ft) fclose(ft);
    if (fh) fclose(fh);
}

int main(void)
{
    signal(SIGINT, on_sig);
    signal(SIGTERM, on_sig);

    struct gpiod_chip *chip = gpiod_chip_open("/dev/gpiochip4");
    if (!chip) { perror("gpiod_chip_open"); return 1; }

    unsigned int pins[4] = { 0, 1, 2, 3 };
    struct gpiod_line_bulk bulk;
    if (gpiod_chip_get_lines(chip, pins, 4, &bulk) < 0) {
        perror("gpiod_chip_get_lines");
        gpiod_chip_close(chip);
        return 1;
    }

    if (gpiod_line_request_bulk_falling_edge_events_flags(
            &bulk, "aesd-sensor-app", GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_UP) < 0) {
        perror("gpiod_line_request_bulk_falling_edge_events_flags");
        gpiod_chip_close(chip);
        return 1;
    }

    struct pollfd pfds[4];
    for (int i = 0; i < 4; i++) {
        pfds[i].fd = gpiod_line_event_get_fd(gpiod_line_bulk_get_line(&bulk, i));
        pfds[i].events = POLLIN;
    }

    print_sht31();
    while (running) {
        int ret = poll(pfds, 4, 2000);
        if (ret < 0 && errno != EINTR) { perror("poll"); break; }
        if (ret == 0) { print_sht31(); continue; }
        for (int i = 0; i < 4; i++) {
            if (pfds[i].revents & POLLIN) {
                struct gpiod_line_event ev;
                if (gpiod_line_event_read(gpiod_line_bulk_get_line(&bulk, i), &ev) == 0) {
                    printf("[BUTTON] MCP23017 line %u pressed! (ts: %ld.%09ld s)\n",
                           pins[i], ev.ts.tv_sec, ev.ts.tv_nsec);
                }
            }
        }
    }

    gpiod_line_release_bulk(&bulk);
    gpiod_chip_close(chip);
    return 0;
}
