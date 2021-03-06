package io.prover.clapperboardmvp.controller;

import android.os.Handler;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Created by babay on 17.11.2017.
 */

public class ListenerList2<T, Q, R> {
    private final List<T> listeners = new CopyOnWriteArrayList<>();

    private final Handler handler;
    private final NotificationRunner<T, Q, R> notificationRunner;

    public ListenerList2(Handler handler, NotificationRunner<T, Q, R> notificationRunner) {
        this.handler = handler;
        this.notificationRunner = notificationRunner;
    }

    public synchronized void add(T listener) {
        if (!listeners.contains(listener))
            listeners.add(listener);
    }

    public synchronized void remove(T listener) {
        listeners.remove(listener);
    }

    void postNotifyEvent(final Q param1, final R param2) {
        handler.post(() -> notifyEvent(param1, param2));
    }

    void notifyEvent(final Q param1, final R param2) {
        for (T listener : listeners) {
            notificationRunner.doNotification(listener, param1, param2);
        }
    }

    public interface NotificationRunner<T, Q, R> {
        void doNotification(T listener, Q param1, R param2);
    }
}
