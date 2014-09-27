import vtk, traceback
from weakref import WeakSet, WeakKeyDictionary
import inspect, ast

class SIGNAL(object):
    
    def __init__( self, name = None ):
        self._functions = WeakSet()
        self._methods = WeakKeyDictionary()
        self._name = name

    def __call__(self, *args, **kargs):
        # Call handler functions
        for func in self._functions:
            func(*args, **kargs)

        # Call handler methods
        for obj, funcs in self._methods.items():
            for func in funcs:
                func(obj, *args, **kargs)

    def connect(self, slot):
        if inspect.ismethod(slot):
            if slot.__self__ not in self._methods:
                self._methods[slot.__self__] = set()

            self._methods[slot.__self__].add(slot.__func__)

        else:
            self._functions.add(slot)

    def disconnect(self, slot):
        if inspect.ismethod(slot):
            if slot.__self__ in self._methods:
                self._methods[slot.__self__].remove(slot.__func__)
        else:
            if slot in self._functions:
                self._functions.remove(slot)

    def clear(self):
        self._functions.clear()
        self._methods.clear()


class AnimationStepper:
    
    def __init__( self, **args ):
        self.animating = False
        self.time_index = 0
        self.delay = args.get( 'delay', 10 )
        self.StartAnimationSignal = SIGNAL('StartAnimationSignal')
        self.StopAnimationSignal = SIGNAL('StopAnimationSignal')
        self.StepAnimationSignal = SIGNAL('StepAnimationSignal')
                
    def setAnimationDelay(self, delay_val ):
        self.delay = delay_val

    def getAnimationDelay(self):
        return self.delay 
    
    def startAnimation(self):
        self.animating = True
        self.notifyStartAnimation()
        self.runAnimation()

    def stopAnimation(self):
        self.animating = False
        self.notifyStopAnimation()           

    def runAnimation( self ):        
        self.notifyStepAnimation( )
        self.updateTimer()
        
    def isAnimating(self):
        return self.animating
    
    def updateTimer( self ):
        # Create timer to execute runAnimation again in self.delay sec.
        pass

    def notifyStepAnimation(self, **args): 
        # Notify listeners that animation has stepped.
        self.StepAnimationSignal( self.time_index, **args )
        self.time_index = self.time_index + 1

    def notifyStartAnimation(self, **args): 
        # Notify listeners that animation has started.
        self.StartAnimationSignal( **args )

    def notifyStopAnimation(self, **args): 
        # Notify listeners that animation has stopped.
        self.StopAnimationSignal( **args )


class VTKAnimationStepper( AnimationStepper ):  

    AnimationTimerType = 9
    AnimationEventId = 9

    def __init__( self, interactor,  **args ):
        AnimationStepper.__init__( self, **args )
        self.renderWindowInteractor = interactor
        self.renderWindowInteractor.AddObserver( 'TimerEvent', self.processTimerEvent )  
        self.animationTimerId = -1    
                              
    def stopAnimation(self):
        AnimationStepper.stopAnimation(self)
        if self.animationTimerId <> -1: 
            self.animationTimerId = -1
            self.renderWindowInteractor.DestroyTimer( self.animationTimerId  ) 

    def updateTimer( self ):
        event_duration = self.getAnimationDelay()
        if self.animationTimerId <> -1: 
            self.renderWindowInteractor.DestroyTimer( self.animationTimerId  )
            self.animationTimerId = -1
        self.renderWindowInteractor.SetTimerEventId( self.AnimationEventId )
        self.renderWindowInteractor.SetTimerEventType( self.AnimationTimerType )
        self.animationTimerId = self.renderWindowInteractor.CreateOneShotTimer( event_duration )  

    def processTimerEvent(self, caller, event):
        eid = caller.GetTimerEventId ()
        etype = caller.GetTimerEventType()
        if self.animating and ( etype == self.AnimationTimerType ):
            self.runAnimation()
        return 1
    
if __name__=='__main__':
    import sys,cdms2,vcs
    x=vcs.init()
    f=cdms2.open(sys.prefix+"/sample_data/clt.nc")
    s=f("clt")    # This will produce 120 frames, in the out frames, it will take them longer to produce.   
    x.plot(s) 
    x.backend.createAnimationStepper()   
    x.interact()
    