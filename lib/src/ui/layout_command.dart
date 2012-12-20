//Copyright (C) 2012 Sergey Akopkokhyants. All Rights Reserved.
//Author: akserg

part of dart_web_toolkit_ui;

/**
 * A scheduled command used by animated layouts to ensure that only layout is
 * ever performed for a panel within a given user event.
 * 
 * <p>
 * Note: This class assumes that {@link com.google.gwt.layout.client.Layout.Layer#getUserObject Layer.getUserObject()} will
 * return the widget associated with a given layer.
 * </p>
 */
class LayoutCommand implements ScheduledCommand {
  
  bool _scheduled, _canceled;
  int _duration;
  LayoutAnimationCallback _callback;
  Layout _layout;

  /**
   * Creates a new command for the given layout object.
   * 
   * @param layout
   */
  LayoutCommand(this._layout);
  
  /**
   * Cancels this command. A subsequent call to
   * {@link #schedule(int, Layout.AnimationCallback)} will re-enable it.
   */
  void cancel() {
    // There's no way to "unschedule" a command, so we use a canceled flag.
    _canceled = true;
  }
  
  /**
   * Invokes the command.
   */
  void execute() {
    _scheduled = false;
    if (_canceled) {
      return;
    }

    doBeforeLayout();

    _layout.layout(_duration, new LayoutCommandAnimationCallback(this));
  }
  
  /**
   * Schedules a layout. The duration and callback passed to this method will
   * supercede any previous call that has not yet been executed.
   * 
   * @param duration
   * @param callback
   */
  void schedule(int duration, LayoutAnimationCallback callback) {
    this._duration = duration;
    this._callback = callback;

    _canceled = false;
    if (!_scheduled) {
      _scheduled = true;
      Scheduler.get().scheduleFinally(this);
    }
  }

  /**
   * Called before the layout is executed. Override this method to perform any
   * work that needs to happen just before it.
   */
  void doBeforeLayout() {
  }
}

class LayoutCommandAnimationCallback implements LayoutAnimationCallback {
  
  LayoutCommand _command;
  
  LayoutCommandAnimationCallback(this._command);
  
  void onAnimationComplete() {
    // Chain to the passed callback.
    if (_command._callback != null) {
      _command._callback.onAnimationComplete();
    }
  }

  void onLayout(Layer layer, double progress) {
    // Inform the child associated with this layer that its size may
    // have changed.
    Widget child = layer.userObject as Widget;
    if (child is RequiresResize) {
      (child as RequiresResize).onResize();
    }

    // Chain to the passed callback.
    if (_command._callback != null) {
      _command._callback.onLayout(layer, progress);
    }
  }
}
