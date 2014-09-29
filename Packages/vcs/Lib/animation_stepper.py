import vtk, traceback, time

class AnimationStepper:
    
    def __init__( self, **args ):
        from Canvas import SIGNAL
        self.animating = False
        self.time_index = 0
        self.delay = args.get( 'delay', 10 )
        self.StartAnimationSignal = SIGNAL('StartAnimationSignal')
        self.StopAnimationSignal = SIGNAL('StopAnimationSignal')
        self.StepAnimationSignal = SIGNAL('StepAnimationSignal')
        self.clockTimeStamp = None
                
    def setAnimationDelay(self, delay_val ):
        self.delay = delay_val

    def getAnimationDelay(self):
        return self.delay 
    
    def startAnimation(self):
        self.animating = True
        self.clockTimeStamp = time.clock()
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
        t1 = time.clock()
        print "Animation DT = %f" % ( t1 - self.clockTimeStamp )
        self.clockTimeStamp = t1

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
        self.renderWindowInteractor = None
        self.animationTimerId = -1 
        self.updateInteractor( interactor )
        
    def updateInteractor( self, interactor ): 
        if  self.renderWindowInteractor <> interactor:
            self.renderWindowInteractor = interactor
            self.renderWindowInteractor.AddObserver( 'TimerEvent', self.processTimerEvent )  
                              
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
    data=f("clt")    # This will produce 120 frames, in the out frames, it will take them longer to produce.  
                   
    x.plot(data) 
    x.interact()
    